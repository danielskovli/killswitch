using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Windows;
using System.Windows.Media;
using Killswitch.Properties;

namespace Killswitch.Classes {
    public static class ThreadHelper {
		public static bool IsLocked { get; set; } = false;
		private static bool run = false;
		public static bool Run {
			get {
				return run;
			}
			set {
				run = value;
				Settings.Default.startStopButton = (value) ? "Pause" : "Start";
				Application.Current.Dispatcher.Invoke(new Action(() => {
					((App)Application.Current).SetTaskbarIcon();
					var mw = Application.Current.MainWindow as MainWindow;
					if (mw != null) {
						mw.UpdateUI();
					}
				}));
			}

		}
		public static bool KillAllThreads { get; set; } = false;
		public static bool CanRun {
			get {
				return (!Settings.Default.authenticated || Settings.Default.token.Length == 0) ? false : true;
				//return (!Settings.Default.authenticated) ? false : true;
			}
		}

		public static string MD5Hash(string input) {
			var md5 = MD5.Create();
			var inputBytes = Encoding.ASCII.GetBytes(input);
			var hash = md5.ComputeHash(inputBytes);

			StringBuilder sb = new StringBuilder();
			for (int i = 0; i < hash.Length; i++) {
				sb.Append(hash[i].ToString("X2"));
			}

			return sb.ToString().ToLower();
		}

		public static bool IsValidEmail(string email) {
			try {
				var addr = new System.Net.Mail.MailAddress(email);
				return addr.Address == email;
			} catch {
				return false;
			}
		}

		public static string OSInfo {
			get {

				OperatingSystem os = Environment.OSVersion;
				Version vs = os.Version;
				string operatingSystem = "";

				if (os.Platform == PlatformID.Win32Windows) {
					//This is a pre-NT version of Windows
					switch (vs.Minor) {
						case 0:
							operatingSystem = "95";
							break;
						case 10:
							if (vs.Revision.ToString() == "2222A")
								operatingSystem = "98SE";
							else
								operatingSystem = "98";
							break;
						case 90:
							operatingSystem = "Me";
							break;
						default:
							break;
					}

				} else if (os.Platform == PlatformID.Win32NT) {
					switch (vs.Major) {
						case 3:
							operatingSystem = "NT 3.51";
							break;
						case 4:
							operatingSystem = "NT 4.0";
							break;
						case 5:
							if (vs.Minor == 0)
								operatingSystem = "2000";
							else
								operatingSystem = "XP";
							break;
						case 6:
							if (vs.Minor == 0)
								operatingSystem = "Vista";
							else if (vs.Minor == 1)
								operatingSystem = "7";
							else if (vs.Minor == 2)
								operatingSystem = "8";
							else
								operatingSystem = "8.1";
							break;
						case 10:
							operatingSystem = "10";
							break;
						default:
							break;
					}
				}

				if (operatingSystem != "") {
					operatingSystem = "Windows " + operatingSystem;

					//See if there's a service pack installed.
					if (os.ServicePack != "") {
						//Append it to the OS name.  i.e. "Windows XP Service Pack 3"
						operatingSystem += " " + os.ServicePack;
					}

				} else {
					operatingSystem = "Unknown";
				}

				return operatingSystem + " (" + Environment.OSVersion.Version.ToString() + ")";
			}
		}
	}
}
