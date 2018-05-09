using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Killswitch.Classes {
    public class URLs {
		public string Status { get; set; } = "http://apps.danielskovli.com/killswitch/api/1.0/status/";
		public string Login { get; set; } = "http://apps.danielskovli.com/killswitch/api/1.0/login/";
		public string AddUser { get; set; } = "http://apps.danielskovli.com/killswitch/api/1.0/user/";
		public string ChangePass { get; set; } = "http://apps.danielskovli.com/killswitch/changePassword.php";
		public string ResetPass { get; set; } = "http://apps.danielskovli.com/killswitch/resetPassword.php";
		public string DeleteAccount { get; set; } = "http://apps.danielskovli.com/killswitch/deleteUser.php";
		public string Website { get; set; } = "http://apps.danielskovli.com/killswitch/";
		public string Download { get; set; } = "http://apps.danielskovli.com/killswitch/#download";
	}
}
