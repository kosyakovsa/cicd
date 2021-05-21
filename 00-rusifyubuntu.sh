sudo apt-get update
sudo apt-get install language-pack-ru
sudo apt-get install language-pack-gnome-ru
#sudo apt-get install libreoffice-l10n-ru
sudo apt-get install hyphen-ru mythes-ru hunspell-ru
sudo rm /etc/default/locale
sudo touch /etc/default/locale
sudo echo "LANG=\"ru_RU.UTF-8\"" >> /etc/default/locale
sudo echo "LANGUAGE=\"ru:en\"" >> /etc/default/locale