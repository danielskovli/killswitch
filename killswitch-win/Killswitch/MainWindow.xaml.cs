using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Reflection;
using Microsoft.Win32;
using Killswitch.Classes;
using Killswitch.Properties;

namespace Killswitch {
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window {

		// Window trackers
		Login loginWindow;
		SignUp signupWindow;

		// Build version
		string buildVersion = Assembly.GetExecutingAssembly().GetName().Version.Major + "." + Assembly.GetExecutingAssembly().GetName().Version.Minor + "." + Assembly.GetExecutingAssembly().GetName().Version.Build;

		// Init window
		public MainWindow() {
            InitializeComponent();

			// Update account info text
			UpdateUI();

			// Listen for changes to the user settings
			Settings.Default.PropertyChanged += SettingChanged;

			// Window title
			this.Title = this.Title + " v" + this.buildVersion + "  –  Preferences";
		}

		// Update UI based on logged in status
		public void UpdateUI() {
			Application.Current.Dispatcher.Invoke(new Action(() => {
				var mw = Application.Current.MainWindow as MainWindow;
				if (mw == null) {
					return;
				}

				// Username
				if (Settings.Default.authenticated) {
					mw.LabelAccount.Content = Settings.Default.name + " <" + Settings.Default.username + ">";
				} else {
					mw.LabelAccount.Content = "Not logged in. Please log in or sign up below";
				}

				// Status
				if (((App)Application.Current).error) {
					mw.Status_Label.Content = Settings.Default.statusText;
					mw.Status_Label.Foreground = Brushes.Red;
				} else if (ThreadHelper.Run) {
					mw.Status_Label.Content = "Killswitch is running";
					mw.Status_Label.Foreground = Brushes.ForestGreen;
				} else {
					mw.Status_Label.Content = (ThreadHelper.CanRun) ? "Killswitch is paused. Use the system tray icon to start it" : "Killswitch is paused. You need to sign in before the system can run";
					mw.Status_Label.Foreground = Brushes.Red;
				}

				// Copyright blurb
				mw.copyBlurb.Content = "Daniel Skovli © " + DateTime.Now.Year.ToString();
			}));

			//copyBlurb
		}

		// Settings have changed. Update acount information in UI
		void SettingChanged(object sender, PropertyChangedEventArgs e) {
			UpdateUI();
		}

		// Window closing, destroy PropertyChanged listener
		private void Window_Closing(object sender, CancelEventArgs e) {
			Settings.Default.PropertyChanged -= SettingChanged;
			CloseAllWindows();

			if (Settings.Default.showBalloonMinimize) {
				((App)Application.Current).notifyIcon.ShowBalloonTip("Killswitch", "The app is still running in your system tray area", Hardcodet.Wpf.TaskbarNotification.BalloonIcon.Info);
				Settings.Default.showBalloonMinimize = false;
			}
		}

		// URL handler
		private void Hyperlink_RequestNavigate(object sender, RequestNavigateEventArgs e) {
			Process.Start(new ProcessStartInfo(e.Uri.AbsoluteUri));
			e.Handled = true;
		}

		// Close all open windows
		private void CloseAllWindows() {
			try {
				loginWindow.Close();
				signupWindow.Close();
			} catch {
				// don't care
			}
		}

		private void ButtonLogin_Click(object sender, RoutedEventArgs e) {
			loginWindow = new Login();
			loginWindow.Show();
			this.IsEnabled = false;
		}

		private void ButtonSignUp_Click(object sender, RoutedEventArgs e) {
			signupWindow = new SignUp();
			signupWindow.Show();
			this.IsEnabled = false;
		}

		private void ButtonLogOut_Click(object sender, RoutedEventArgs e) {
			Settings.Default.authenticated = false;
			Settings.Default.token = "";
			Settings.Default.name = "";
			Settings.Default.username = "";
			ThreadHelper.Run = false;
		}

		private void Status_StartStop_Click(object sender, RoutedEventArgs e) {
			ThreadHelper.Run = !ThreadHelper.Run;
		}
	}
}
