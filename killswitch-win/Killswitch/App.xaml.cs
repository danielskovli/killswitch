using System;
using System.ComponentModel;
using System.Windows;
using Hardcodet.Wpf.TaskbarNotification;
using Killswitch.Properties;
using Microsoft.Win32;
using Killswitch.Classes;
using System.Threading;
using System.Windows.Controls;
using System.Reflection;

namespace Killswitch {
    /// <summary>
    /// Simple application. Check the XAML for comments.
    /// </summary>
    public partial class App : Application {
        public TaskbarIcon notifyIcon;
		public ListenerThread listenerThread = new ListenerThread();
		public Thread listener;

		// Startup
		protected override void OnStartup(StartupEventArgs e) {
            base.OnStartup(e);

			// Create, but don't display, the main window (inits to something not-null, which is weird. This is a workaround)
			Current.MainWindow = new MainWindow();

			//create the notifyicon (it's a resource declared in NotifyIconResources.xaml
			notifyIcon = (TaskbarIcon)FindResource("NotifyIcon");

			// Uprade user settings from previous version if required
			if (Settings.Default.upgradeUserSettings) {
				Settings.Default.Upgrade();
				Settings.Default.upgradeUserSettings = false;
				Settings.Default.Save();
			}

			// Set auto start preference
			SetAutoStart();

			// If we're not authenticated, pop up the main window
			if (!ThreadHelper.CanRun) {
				ThreadHelper.Run = false; // this must always be set, to cascade some setter properties
				Current.MainWindow.Show();

			// If we're good to go, start the show
			} else {
				ThreadHelper.Run = true;
			}

			// Set taskbar icon
			SetTaskbarIcon();

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

			if (e.PropertyName == "launchAtLogin") {
				SetAutoStart();
			}
		}

		// Add/remove auto start flag from windows registry
		private void SetAutoStart() {
			RegistryKey rk = Registry.CurrentUser.OpenSubKey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run", true);

			if (Settings.Default.launchAtLogin) {
				try {
					rk.SetValue("Killswitch", Assembly.GetExecutingAssembly().Location);
					Console.WriteLine("Enabling app auto start");
					Console.WriteLine(Assembly.GetExecutingAssembly().Location);
				} catch {
					Console.WriteLine("Could not enable app auto start");
					MessageBox.Show("Could not enable auto-start for the Killswitch app. This is most likely due to a permission error. Try running the application as Administrator or granting the current user elevated permissions", "Killswitch error", MessageBoxButton.OK, MessageBoxImage.Error);
				}
			} else {
				try {
					rk.DeleteValue("Killswitch", false);
					Console.WriteLine("Disabling app auto start");
				} catch {
					Console.WriteLine("Could not disable app auto start");
					MessageBox.Show("Could not disable auto-start for the Killswitch app. This is most likely due to a permission error. Try running the application as Administrator or granting the current user elevated permissions", "Killswitch error", MessageBoxButton.OK, MessageBoxImage.Error);
				}
			}
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

		// Update taskbar icon
		public void SetTaskbarIcon() {
			SetTaskbarIcon(ThreadHelper.Run);
		}
		public void SetTaskbarIcon(bool enabled) {
			if (enabled) {
				notifyIcon.Icon = Killswitch.Properties.Resources.LockEnabled;
				notifyIcon.ToolTipText = "Killswitch"+ Environment.NewLine +"System running";
			} else {
				notifyIcon.Icon = Killswitch.Properties.Resources.LockDisabled;
				notifyIcon.ToolTipText = (ThreadHelper.CanRun) ? "Killswitch" + Environment.NewLine + "System paused" : "Killswitch" + Environment.NewLine + "Not signed in";
			}
		}
	}
}
