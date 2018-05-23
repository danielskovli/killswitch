using Killswitch.Classes;
using Killswitch.Properties;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
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

			// Check form values
			if (string.IsNullOrWhiteSpace(this.Fullname.Text)) {
				MessageBox.Show("You must provide a name for this account. If you're the secretive type - make up something fun...", "Name error", MessageBoxButton.OK, MessageBoxImage.Warning);
				this.Fullname.Focus();
				return;
			} else if (!ThreadHelper.IsValidEmail(this.Email.Text)) {
				MessageBox.Show("You need to specify a valid email address to sign up. This will become your username", "Email error", MessageBoxButton.OK, MessageBoxImage.Warning);
				this.Email.Focus();
				return;
			} else if (string.IsNullOrWhiteSpace(this.Password.Password)) {
				MessageBox.Show("You need to specify a password for your account", "Password error", MessageBoxButton.OK, MessageBoxImage.Warning);
				this.Password.Focus();
				return;
			} else if (this.Password.Password != this.PasswordRepeat.Password) {
				MessageBox.Show("The passwords you entered don't match eachother. Aren't you glad we checked this now?", "Password error", MessageBoxButton.OK, MessageBoxImage.Warning);
				this.Password.Focus();
				return;
			}

			// Disable the window while we send the request
			this.IsEnabled = false;
			var cursor = Mouse.OverrideCursor;
			Mouse.OverrideCursor = Cursors.Wait;

			// Talk to server
			using (var webClient = new WebClient()) {
				var payload = JsonConvert.SerializeObject(new {
					username = this.Email.Text,
					password = ThreadHelper.MD5Hash(this.Password.Password),
					name = this.Fullname.Text
				});

				webClient.Headers[HttpRequestHeader.ContentType] = "application/json";
				webClient.Headers[HttpRequestHeader.UserAgent] = ThreadHelper.OSInfo + "; " + Assembly.GetExecutingAssembly().GetName().Name.ToString() + " " + Assembly.GetExecutingAssembly().GetName().Version.ToString();

				try {
					// Success
					var response = webClient.UploadString(new URLs().AddUser, payload);
					var json = JsonConvert.DeserializeObject<Dictionary<string, object>>(response);
					Settings.Default.authenticated = true;
					Settings.Default.name = json["name"].ToString();
					Settings.Default.username = json["username"].ToString();
					Settings.Default.token = json["token"].ToString();
					MessageBox.Show("Thanks for signing up " + this.Fullname.Text.Split(' ').First() + ", welcome to the family!", "Sign up successful", MessageBoxButton.OK, MessageBoxImage.None);
					ThreadHelper.Run = true;
					this.Close();

				} catch (WebException err) {

					// Authentication error
					if (err.Response != null) {
						var response = new StreamReader(err.Response.GetResponseStream()).ReadToEnd();
						var json = JsonConvert.DeserializeObject<Dictionary<string, object>>(response);
						if (json.ContainsKey("error")) {
							MessageBox.Show("Unable to sign up. Server said: " + (string)json["error"], "Sign up error", MessageBoxButton.OK, MessageBoxImage.Error);
						} else {
							MessageBox.Show("Unable to sign up. Unknown server error. Please try again", "Sign up error", MessageBoxButton.OK, MessageBoxImage.Error);
						}

						// Server or network error
					} else {
						MessageBox.Show("Network unreachable. Please check your connection and try again", "Network error", MessageBoxButton.OK, MessageBoxImage.Error);
					}
				} finally {
					this.IsEnabled = true;
					Mouse.OverrideCursor = cursor;
				}
			}
		}

		private void ButtonCancel_Click(object sender, RoutedEventArgs e) {
			this.Close();
		}
	}
}
