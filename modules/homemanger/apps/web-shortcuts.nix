{ ... }:
{
  # Quick link desktop entries that appear as regular apps in the launcher
  home.file.".local/share/applications/facebook.desktop".text = ''
    [Desktop Entry]
    Name=Facebook
    Comment=Open Facebook
    Exec=firefox https://facebook.com
    Icon=web-browser
    Type=Application
    Terminal=false
    Categories=Network;WebBrowser;
  '';

  home.file.".local/share/applications/whatsapp.desktop".text = ''
    [Desktop Entry]
    Name=WhatsApp
    Comment=Open WhatsApp Web
    Exec=firefox https://web.whatsapp.com/
    Icon=web-browser
    Type=Application
    Terminal=false
    Categories=Network;WebBrowser;
  '';

  home.file.".local/share/applications/todo.desktop".text = ''
    [Desktop Entry]
    Name=To Do
    Comment=Open To Do
    Exec=firefox https://to-do.live.com/tasks/myday
    Icon=web-browser
    Type=Application
    Terminal=false
    Categories=Network;WebBrowser;
  '';

  home.file.".local/share/applications/gdocs.desktop".text = ''
    [Desktop Entry]
    Name=Google Docs
    Comment=Open Google Docs
    Exec=firefox https://docs.google.com/document/u/0/
    Icon=web-browser
    Type=Application
    Terminal=false
    Categories=Network;WebBrowser;
  '';

  home.file.".local/share/applications/youtube.desktop".text = ''
    [Desktop Entry]
    Name=YouTube
    Comment=Open YouTube
    Exec=firefox https://www.youtube.com/
    Icon=web-browser
    Type=Application
    Terminal=false
    Categories=Network;WebBrowser;
  '';

  home.file.".local/share/applications/poster.desktop".text = ''
    [Desktop Entry]
    Name=Poster
    Comment=Open Canva Poster
    Exec=firefox https://www.canva.com/design/DAG_uUX3GQ0/FMUuQ6Z62RlXt7kEi2FxEA/edit
    Icon=web-browser
    Type=Application
    Terminal=false
    Categories=Network;WebBrowser;
  '';
}
