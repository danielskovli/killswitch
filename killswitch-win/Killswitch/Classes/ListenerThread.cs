using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows;
using Killswitch.Classes;
using Killswitch.Properties;
using Newtonsoft.Json;

namespace Killswitch.Classes {
    public class ListenerThread {

		private readonly bool debug = false;
		private readonly int listenInterval = 3000;
		private URLs urls = new URLs();
		//private bool error = false;

		public void Listen() {

			// Take a nap if we're locked or paused
			if (ThreadHelper.IsLocked || !ThreadHelper.Run) {
				DebugLog("Paused");

				if (!((App)Application.Current).error) {
					if (ThreadHelper.CanRun) {
						Settings.Default.statusText = "System paused";
					} else {
						Settings.Default.statusText = "Not logged in";
					}
				}

				Thread.Sleep(1000);
				Iterate();
				return;
			}

			// Are we logged in - or at least think we are?
			if (!ThreadHelper.CanRun) {
				DebugLog("Not logged in");
				Settings.Default.statusText = "Not logged in";
				Thread.Sleep(1000);
				Iterate();
			}

			// Talk to server
			using (var webClient = new WebClient()) {
				webClient.Headers[HttpRequestHeader.ContentType] = "application/json";

				try {
					// Success
					var response = webClient.DownloadString(urls.Status + Settings.Default.token);
					var json = JsonConvert.DeserializeObject<Dictionary<string, object>>(response);
					
					DebugLog("Running");
					((App)Application.Current).error = false;
					Settings.Default.statusText = "System running";

					// Take action if killswitch is set
					if ((bool)json["killswitch"]) {
						switch (Settings.Default.killswitchAction) {

							// System sleep
							case "Sleep":
								DebugLog("Initiating sleep");
								Sleep();
								break;
							
							// System shutdown
							case "Shutdown":
								DebugLog("Initiating system shutdown");
								Settings.Default.Save();
								Shutdown();
								break;
							
							// System lock & catch-all in case our config is fucked
							default:
								DebugLog("Locking system");
								Lock();
								break;
						}
					}

				} catch (WebException err) {

					((App)Application.Current).error = true;

					// Authentication error
					if (err.Response != null) {
						var response = new StreamReader(err.Response.GetResponseStream()).ReadToEnd();
						var json = JsonConvert.DeserializeObject<Dictionary<string, object>>(response);
						if (json.ContainsKey("error")) {
							Settings.Default.authenticated = false;
							ThreadHelper.Run = false;
							Application.Current.Dispatcher.Invoke(new Action(() => {
								((App)Application.Current).notifyIcon.ShowBalloonTip("Session expired", "Your authentication was rejected by the server, please sign in again", Hardcodet.Wpf.TaskbarNotification.BalloonIcon.Error);
							}));
							
						} else {
							// Weird error, possibly server issue. Keep running
							Settings.Default.statusText = "Server error";
						}

					// Server or network error
					} else {
						// Keep running
						Settings.Default.statusText = "Network error";
					}

				} finally {
					Thread.Sleep(listenInterval);
					Iterate();
				}
			}
		}

		public void Iterate() {
			if (!ThreadHelper.KillAllThreads) {
				Listen();
			}
		}

		void DebugLog(string what) {
			if (!debug) {
				return;
			}
			Console.WriteLine(what);
		}


		// Wrappers
		public static void Lock() {
			NativeMethods.LockWorkStation();
		}

		public static void Sleep() {
			NativeMethods.SetSuspendState(false, true, true);
		}

		public static void Shutdown() {
			var psi = new ProcessStartInfo("shutdown", "/s /t 0") {
				CreateNoWindow = true,
				UseShellExecute = false
			};
			Process.Start(psi);
		}
	}

	// External code
	internal static class NativeMethods {
		[DllImport("user32")]
		public static extern void LockWorkStation();

		[DllImport("Powrprof.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
		public static extern bool SetSuspendState(bool hiberate, bool forceCritical, bool disableWakeEvent);
	}
}
