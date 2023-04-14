# Game of QR

This app is based on an idea of my brother: [App idea: Game of QR](https://bassistance.de/2022/01/15/app-idea-game-of-qr/). He implemented it in React Nativ, I in Flutter.

The idea is, you point the camera of your phone on a QR code, and the app will start [Conway's Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) with the pixels of the QR code as the initial generation. Either as a centered Overlay, or in an AR mode exactly above the QR code where it was found.

There are two concessions I had to make:
1) I use Google's ML Kit to detect QR codes in an image, but the library does not give information about the orientation of a found QR code. Scanning a QR code will work with every rotation, but the Game of Life will always be displayed as if the code was scanned without rotation in portrait mode.
2) Google's ML Kit only gives back the content of the QR code, but neither the raw pattern of the code, nor information about the error correction level used in the QR code. So a new QR code based on the the content is created for the Game of Life, which means the initial frame will be different from the original if the error correction levels differ.

The app has only been tested with Android and iOS.

For the AR mode the Game of Life must be transformed for it to be displayed above the found QR code. However, the rectanlge around that code will be distorted due to perspective, it's form is called an irregular convex quadrilateral. I had help on how to calculate the transformation matrix for that ([see here](https://stackoverflow.com/a/74030319/441264)).
