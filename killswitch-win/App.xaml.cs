using System;
using System.ComponentModel;
using System.Windows;
using Hardcodet.Wpf.TaskbarNotification;
using Killswitch.Properties;
using Microsoft.Win32;
using Killswitch.Classes;
using System.Threading;
using System.Windows.Controls;

namespace Killswitch {
    /// <summary>
    /// Simple application. Check the XAML for comments.
    /// </summary>
    public partial class App : Application
    {
        private TaskbarIcon notifyIcon;
		public ListenerThread listenerThread = new ListenerThread();
		public Thread listener;

		// Startup
		protected override void OnStartup(StartupEventArgs e) {
            base.OnStartup(e);

			// Create, but don't display, the main window (inits to something not-null, which is weird. This is a workaround)
			Current.MainWindow = new MainWindow();

			// If we're not authenticated, pop up the main window
			if (!ThreadHelper.CanRun) {
				Current.MainWindow.Show();
			}

			//create the notifyicon (it's a resource declared in NotifyIconResources.xaml
			notifyIcon = (TaskbarIcon) FindResource("NotifyIcon");

			// Uprade user settings from previous version if required
			if (Settings.Default.upgradeUserSettings) {
				Settings.Default.Upgrade();
				Settings.Default.upgradeUserSettings = false;
				Settings.Default.Save();
			}

			// Initialize system. Run status and menu text, handled in Threadhelper
			ThreadHelper.Run = (ThreadHelper.CanRun);

			// Listen for changes to the user settings
			Settings.Default.PropertyChanged += SettingChanged;

			// Listen for system session events
			SystemEvents.SessionSwitch += new SessionSwitchEventHandler(SystemEvents_SessionSwitch);

			// Start listener thread
			listener = new Thread(listenerThread.Listen) {
				IsBackground = true
			};
			listener.Start();
		}

		// Exit
        protected override void OnExit(ExitEventArgs e) {
            notifyIcon.Dispose(); //the icon would clean up automatically, but this is cleaner
            base.OnExit(e);
        }

		// Settings have changed. Save and update GUI if needed
		void SettingChanged(object sender, PropertyChangedEventArgs e) {
			Settings.Default.Save();
		}

		// Session has changed. Notify threads
		void SystemEvents_SessionSwitch(object sender, SessionSwitchEventArgs e) {
			if (e.Reason == SessionSwitchReason.SessionLock) {
				ThreadHelper.IsLocked = true;
			}
			else if (e.Reason == SessionSwitchReason.SessionUnlock) {
				ThreadHelper.IsLocked = false;
			}
		}
	}
}
