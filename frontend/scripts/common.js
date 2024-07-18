export const socketURL = "ws://127.0.0.1:8000/";

export const uiPositions = Object.freeze({
    TOP: 0,
    BOTTOM: 1,
    LEFT: 2,
    RIGHT: 3
});

/*  placeUI
    Places the side and width bars on the right or left, and top or bottom respectively.
    Parameters can be changed to accomodate for handedness of participant.

    Inputs:
        rightleft: UI_POSITIONS
            Determines if the sidebar will be on the right or left side of the screen.
        topbottom: UI_POSITIONS
            Determines if the widthbar will be on the top or bottom of the screen.

    Outputs:
        boolean
            True if function is successful, false if failed
*/
export function placeUI(rightleft, topbottom) {
    var sidebars = document.getElementsByClassName("sidebar");
    var widthbars = document.getElementsByClassName("widthbar");

    var sidebarWidth = getComputedStyle(document.body).getPropertyValue("--sideWidth");

    sidebars[0].style.top = "0px";

    switch(rightleft) {
        case uiPositions.RIGHT:
            sidebars[0].style.right = "0px";
            widthbars[0].style.right = sidebarWidth;
            break;
        case uiPositions.LEFT:
            sidebars[0].style.left = "0px";
            widthbars[0].style.left = sidebarWidth;
            break;
        default:
            console.error("Receieved an invalid position for sidebar");
            return false;
    }

    switch(topbottom) {
        case uiPositions.TOP:
            widthbars[0].style.top = "0px";
            break;
        case uiPositions.BOTTOM:
            widthbars[0].style.bottom = "0px";
            break;
        default:
            console.error("Receieved an invalid position for widthbar");
            return false;
    }

    return true;
}

/*  openSidebarTab
	Gets the element with the given ID, sets its display to "flex", then sets the
	displays of all sidebarTab elements to "none". Enables switching between tabs.

	Inputs:
		tabID: str
			The ID of the element you want to switch to; should be a sidebarTab 
            element
*/
export function openSidebarTab(tabID) {
	var tab = document.getElementById(tabID);
    var tabContent = document.getElementsByClassName("sidebarTab");
    for (var i = 0; i < tabContent.length; i++) {
        tabContent[i].style.display = "none";
    }
    tab.style.display = "flex";
}

/*  activatePaletteButton
    Palette buttons are elements intended to change the behavior of the controls
    on the 
*/
export function activatePaletteButton(buttonID) {
    var imageButtons = document.getElementsByClassName("paletteButton");
	for (var i = 0; i < imageButtons.length; i++) {
        imageButtons[i].classList.remove("active")
    }
	document.getElementById(buttonID).classList.add("active");
}