import { Vector2 } from "three";

export const socketURL = "ws://127.0.0.1:8000/";

export const uiPositions = Object.freeze({
    TOP: 0,
    BOTTOM: 1,
    LEFT: 2,
    RIGHT: 3
});

/*  placeUI
    Places the side and width bars on the right or left, and top or bottom 
    respectively. Parameters can be changed to accomodate for handedness of 
    participant.

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
    const sidebars = document.getElementsByClassName("sidebar");
    const widthbars = document.getElementsByClassName("widthbar");
    const threeDContainer = document.getElementById("3dContainer");

    const sidebarWidth = getComputedStyle(document.body).
                            getPropertyValue("--sideWidth");

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
            threeDContainer.style.top = getComputedStyle(document.body).
                                        getPropertyValue("--widthbarHeight");
            break;
        case uiPositions.BOTTOM:
            widthbars[0].style.bottom = "0px";
            threeDContainer.style.bottom = getComputedStyle(document.body).
                                            getPropertyValue("--widthbarHeight");
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
    Palette buttons are elements intended to change the behavior of the viewport
    controls; this function changes the style of the palette button to reflect
    that it is the one that is "active", while making every other button
    "inactive"

    Inputs:
        buttonID: str
            The ID of the palette button element to be activated
*/
export function activatePaletteButton(buttonID) {
    var imageButtons = document.getElementsByClassName("paletteButton");
	for (var i = 0; i < imageButtons.length; i++) {
        imageButtons[i].classList.remove("active")
    }
	document.getElementById(buttonID).classList.add("active");
}

/*  horizontalLine
    Returns a set of points representing a horizontal line starting at given
    start position startX and ending at endX at a given y position

    Inputs:
        xStart: int
            The x coordinate to start at
        xEnd: int
            The x coordinate to end at
        y: int
            The y coordinate of the line

    Outputs:
        line: list of Vector2
*/
export function horizontalLine(xStart, xEnd, y) {
    var line = [];

    for (var i = xStart; i <= xEnd; i++) {
        line.push(new Vector2(i, y));
    }

    return line;
}

/*  midpointCircle
    Performs the midpoint circle algorithm on a given x,y midpoint, generating
    a set of points representing a circle of a given radius

    Adapted from: 
    https://stackoverflow.com/questions/10878209/

    Inputs:
        xCenter: int
            The x coordinate of the midpoint
        yCenter: int
            The y coordinate of the midpoint
        radius: int
            The radius of the desired circle

    Outputs:
        points_set: list of Vector2
            The points which represent the circle matching given parameters
*/
export function midpointCircle(centerX, centerY, radius) {
    var x = radius, y = 0, err = 1 - x;

    var circle = [];

    while (x >= y) {
        var startX = -x + centerX;
        var endX = x + centerX;

        circle = circle.concat(horizontalLine(startX, endX, y + centerX));

        if (y != 0) {
            circle = circle.concat(horizontalLine(startX, endX, -y + centerY));
        }

        y++;

        if (err < 0) {
            err += 2 * y + 1;
        }
        else {
            if (x >= y) {
                startX = -y + 1 + centerX;
                endX = y - 1 + centerX;
                circle = circle.concat(horizontalLine(startX, endX, x + centerY));
                circle = circle.concat(horizontalLine(startX, endX, -x + centerY));
            }
            x--;
            err += 2 * (y - x + 1);
        }
    }

    return circle;
}