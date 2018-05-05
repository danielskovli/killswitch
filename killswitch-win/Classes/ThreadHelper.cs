using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
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
			}

		}
		public static bool KillAllThreads { get; set; } = false;
		public static bool CanRun {
			get {
				//return (!Settings.Default.authenticated || Settings.Default.token.Length == 0) ? false : true;
				return (!Settings.Default.authenticated) ? false : true;
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
	}
}
