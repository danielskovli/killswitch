using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace Killswitch {
    /// <summary>
    /// Interaction logic for SignUp.xaml
    /// </summary>
    public partial class SignUp : Window {
        public SignUp() {
            InitializeComponent();
        }

		private void Window_Closed(object sender, EventArgs e) {
			try {
				Application.Current.MainWindow.IsEnabled = true;
			} catch {
				Console.WriteLine("Couldn't re-enable main window");
			}
		}

		private void ButtonSignUp_Click(object sender, RoutedEventArgs e) {

		}

		private void ButtonCancel_Click(object sender, RoutedEventArgs e) {
			this.Close();
		}
	}
}
