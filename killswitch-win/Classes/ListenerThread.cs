using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using Killswitch.Classes;
using Killswitch.Properties;

namespace Killswitch.Classes {
    public class ListenerThread {

		bool debug = false;
		int listenInterval = 3000;

		public void Listen() {

			// Take a nap if we're locked or paused
			if (ThreadHelper.IsLocked || !ThreadHelper.Run) {
				DebugLog("Paused");
				Settings.Default.statusText = "System paused";
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

			// All good, lets get some JSON
			DebugLog("Running");
			Settings.Default.statusText = "System running";


			Thread.Sleep(listenInterval);
			Iterate();


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

		// External code
		[DllImport("user32")]
		public static extern void LockWorkStation();
		[DllImport("Powrprof.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
		public static extern bool SetSuspendState(bool hiberate, bool forceCritical, bool disableWakeEvent);

		// Wrappers
		public static void Lock() {
			LockWorkStation();
		}

		public static void Sleep() {
			SetSuspendState(false, true, true);
		}

		public static void Shutdown() {
			var psi = new ProcessStartInfo("shutdown", "/s /t 0");
			psi.CreateNoWindow = true;
			psi.UseShellExecute = false;
			Process.Start(psi);
		}
	}
}
