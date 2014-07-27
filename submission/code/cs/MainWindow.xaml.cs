using ICSharpCode.AvalonEdit.Highlighting;
using ICSharpCode.AvalonEdit.Highlighting.Xshd;
using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Media;
using System.Windows.Input;
using System.Windows.Forms;
namespace GHCEditor
{
    /// <summary>
    /// MainWindow.xaml の相互作用ロジック
    /// </summary>
    public partial class MainWindow : Window
    {
        public string FileName { get; set; }
        public MainWindow()
        {
            InitializeComponent();
            var reader = System.Xml.XmlReader.Create("GHC.xshd");
            var definition = HighlightingLoader.Load(reader, HighlightingManager.Instance);
            this.Editor.SyntaxHighlighting = definition;
            this.Editor.Background = Brushes.Black;
            this.Editor.Foreground = Brushes.White;
            this.Editor.Focus();
            FileName = "tmp.mofu";
        }

        private void saveClick(object sender, RoutedEventArgs e)
        {
            if (FileName != "tmp.mofu")
            { 
                save();
                return;
            }
            var dialog = new SaveFileDialog();
            dialog.DefaultExt = ".mofu";
            dialog.Filter = "mofuファイル|*.mofu";
            if (dialog.ShowDialog() != System.Windows.Forms.DialogResult.OK)
                return;
            this.FileName = dialog.FileName;
            var li = this.FileName.LastIndexOf('\\');
            this.Header.Header = this.FileName.Substring(li+1);
            save();
        }
        private void save()
        {
            try
            {
                using (var stream = new FileStream(FileName, FileMode.Create, FileAccess.Write, FileShare.Read))
                using (var sw =new StreamWriter(stream))
                    sw.Write(this.Editor.Text);
                this.Notify.Content = "saved...";
            }
            catch
            {
                this.Notify.Content = "failed to save";
            }
        }

        private void buildClick(object sender, RoutedEventArgs e)
        {
            build();
        }
        private void build()
        {/*
            save();
            var li = this.FileName.LastIndexOf('.');
            var newFileName = this.FileName.Substring(0, li) + ".ghc";
            var format = string.Format("{0} >{1}", this.FileName, newFileName);
            var p = new Process();
            p.StartInfo = new ProcessStartInfo("tippy.rb", newFileName);
            p.Start();

            */
        }

        private void openClick(object sender, RoutedEventArgs e)
        {
            var dlg = new OpenFileDialog();
            dlg.Filter = "mofuファイル|*.mofu";
            if (dlg.ShowDialog() != System.Windows.Forms.DialogResult.OK)
                return;
            this.FileName = dlg.FileName;
            var li = this.FileName.LastIndexOf('\\');
            this.Header.Header = this.FileName.Substring(li + 1);
            using (var stream = new FileStream(FileName, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (var sr = new StreamReader(stream))
                this.Editor.Text = sr.ReadToEnd();
        }
        
        protected override void OnPreviewKeyDown(System.Windows.Input.KeyEventArgs e)
        {
            var key = e.Key;
            if (key == System.Windows.Input.Key.F5)
                build();
            if( (Keyboard.Modifiers & ModifierKeys.Control) > 0)
            {
                if (key == Key.S)
                {
                    saveClick(null, null);
                    e.Handled = true;
                }
                else if (key == Key.O)
                {
                    openClick(null, null);
                    e.Handled = true;
                }
                else if (key == Key.N)
                {
                    newFileClick(null, null);
                    e.Handled = true;
                }
            }
            base.OnPreviewKeyDown(e);
           
        }

        private void newFileClick(object sender, RoutedEventArgs e)
        {
            this.FileName = "tmp.mofu";
            this.Header.Header = "tmp.mofu";
            this.Editor.Text = "";
        }

    }
}
