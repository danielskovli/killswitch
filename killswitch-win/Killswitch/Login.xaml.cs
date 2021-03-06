﻿using System;
using System.Collections.Generic;
using System.Diagnostics;
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
using System.Net;
using Newtonsoft.Json;
using Killswitch.Properties;
using Killswitch.Classes;
using System.IO;

namespace Killswitch {
    /// <summary>
    /// Interaction logic for Login.xaml
    /// </summary>
    public partial class Login : Window {
        public Login() {
            InitializeComponent();
        }

		// URL handler
		private void Hyperlink_RequestNavigate(object sender, System.Windows.Navigation.RequestNavigateEventArgs e) {
			Process.Start(new ProcessStartInfo(e.Uri.AbsoluteUri));
			e.Handled = true;
		}

		private void Window_Closed(object sender, EventArgs e) {
			try {
				Application.Current.MainWindow.IsEnabled = true;
			} catch {
				Console.WriteLine("Couldn't re-enable main window");
			}
		}

		private void ButtonCancel_Click(object sender, RoutedEventArgs e) {
			this.Close();
		}

		private void ButtonLogin_Click(object sender, RoutedEventArgs e) {

			// Check form values
			if (string.IsNullOrWhiteSpace(this.Email.Text)) {
				MessageBox.Show("You need to specify a username to log in. Your username is the email address you signed up with", "Username error", MessageBoxButton.OK, MessageBoxImage.Warning);
				this.Email.Focus();
				return;
			} else if (string.IsNullOrWhiteSpace(this.Password.Password)) {
				MessageBox.Show("You need to specify a password to log in", "Password error", MessageBoxButton.OK, MessageBoxImage.Warning);
				this.Password.Focus();
				return;
			}

			this.IsEnabled = false;
			var cursor = Mouse.OverrideCursor;
			Mouse.OverrideCursor = Cursors.Wait;
			var url = new URLs().Login;

			using (var webClient = new WebClient()) {
				var payload = JsonConvert.SerializeObject(new {
					username = this.Email.Text,
					password = ThreadHelper.MD5Hash(this.Password.Password)
				});

				webClient.Headers[HttpRequestHeader.ContentType] = "application/json";

				try {
					// Success
					var response = webClient.UploadString(url, payload);
					var json = JsonConvert.DeserializeObject<Dictionary<string, object>>(response);
					Settings.Default.authenticated = true;
					Settings.Default.name = json["name"].ToString();
					Settings.Default.username = json["username"].ToString();
					Settings.Default.token = json["token"].ToString();
					ThreadHelper.Run = true;
					this.Close();

				} catch (WebException err) {

					// Authentication error
					if (err.Response != null) {
						var response = new StreamReader(err.Response.GetResponseStream()).ReadToEnd();
						var json = JsonConvert.DeserializeObject<Dictionary<string, object>>(response);
						if (json.ContainsKey("error")) {
							MessageBox.Show("Unable to log in. Server said: " + (string)json["error"], "Authentication error", MessageBoxButton.OK, MessageBoxImage.Error);
						} else {
							MessageBox.Show("Unable to log in. Unknown server error. Please try again", "Authentication error", MessageBoxButton.OK, MessageBoxImage.Error);
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
	}
}
