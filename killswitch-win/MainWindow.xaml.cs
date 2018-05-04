using Killswitch.Properties;
using System;
using System.Collections.Generic;
using System.ComponentModel;
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

namespace Killswitch {
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window {
        public MainWindow() {
            InitializeComponent();

			// Update account info text
			UpdateIU();

			// Listen for changes to the user settings
			Settings.Default.PropertyChanged += SettingChanged;
		}

		void UpdateIU() {
			if (Settings.Default.authenticated) {
				this.LabelAccount.Content = Settings.Default.name + " <" + Settings.Default.username + ">";
			} else {
				this.LabelAccount.Content = "Not logged in. Please log in or sign up below";
			}
		}

		// Settings have changed. Update acount information in UI
		void SettingChanged(object sender, PropertyChangedEventArgs e) {
			Console.WriteLine("triggered");
			UpdateIU();
		}

		private void Window_Closing(object sender, CancelEventArgs e) {
			Settings.Default.PropertyChanged -= SettingChanged;
		}
	}
}
