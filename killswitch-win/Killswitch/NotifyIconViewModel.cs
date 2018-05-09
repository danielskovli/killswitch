using System;
using System.Windows;
using System.Windows.Input;
using Killswitch.Classes;

namespace Killswitch {
    /// <summary>
    /// Provides bindable properties and commands for the NotifyIcon. In this sample, the
    /// view model is assigned to the NotifyIcon in XAML. Alternatively, the startup routing
    /// in App.xaml.cs could have created this view model, and assigned it to the NotifyIcon.
    /// </summary>
    public class NotifyIconViewModel {
        /// <summary>
        /// Shows a window, if none is already open.
        /// </summary>
        public ICommand ShowWindowCommand {
            get {
                return new DelegateCommand {
                    CommandAction = () => {
						if (Application.Current.MainWindow == null) {
							Application.Current.MainWindow = new MainWindow();
							Application.Current.MainWindow.Show();
						} else if (Application.Current.MainWindow.IsLoaded) {
							Application.Current.MainWindow.WindowState = WindowState.Normal;
							Application.Current.MainWindow.Activate();
						} else {
							Application.Current.MainWindow.Show();
						}
					}
                };
            }
        }


        /// <summary>
        /// Shuts down the application.
        /// </summary>
        public ICommand ExitApplicationCommand {
            get {
                return new DelegateCommand {CommandAction = () => Application.Current.Shutdown()};
            }
        }

		public ICommand ToggleStartStopCommand {
			get {
				return new DelegateCommand {
					CommandAction = () => ThreadHelper.Run = !ThreadHelper.Run,
					CanExecuteFunc = () => ThreadHelper.CanRun
				};
			}
		}
    }


    /// <summary>
    /// Simplistic delegate command for the demo.
    /// </summary>
    public class DelegateCommand : ICommand {
        public Action CommandAction { get; set; }
        public Func<bool> CanExecuteFunc { get; set; }

        public void Execute(object parameter) {
            CommandAction();
        }

        public bool CanExecute(object parameter) {
            return CanExecuteFunc == null  || CanExecuteFunc();
        }

        public event EventHandler CanExecuteChanged {
            add { CommandManager.RequerySuggested += value; }
            remove { CommandManager.RequerySuggested -= value; }
        }
    }
}
