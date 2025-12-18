script 

sudo apt install flatpak
sudo apt install gnome-software-plugin-flatpak

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

which flatpak
# with flatpak install sober 

# ==================================

dpkg --add-architecture i386 && apt-get update && apt-get install wine32:i386


# install studio 
flatpak install flathub org.vinegarhq.Vinegar

# ask the user to run or not or create launch logo 

flatpak run org.vinegarhq.Vinegar

