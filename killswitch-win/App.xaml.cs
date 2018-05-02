using System.ComponentModel;
using System.Windows;
using Hardcodet.Wpf.TaskbarNotification;
using Killswitch.Properties;

namespace Killswitch {
    /// <summary>
    /// Simple application. Check the XAML for comments.
    /// </summary>
    public partial class App : Application
    {
        private TaskbarIcon notifyIcon;


		// Startup
        protected override void OnStartup(StartupEventArgs e) {
            base.OnStartup(e);

            //create the notifyicon (it's a resource declared in NotifyIconResources.xaml
            notifyIcon = (TaskbarIcon) FindResource("NotifyIcon");

			// Uprade user settings from previous version if required
			if (Settings.Default.upgradeUserSettings) {
				Settings.Default.Upgrade();
				Settings.Default.upgradeUserSettings = false;
				Settings.Default.Save();
			}

			// Listen for changes to the user settings
			Settings.Default.PropertyChanged += SettingChanged;
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
	}
}
