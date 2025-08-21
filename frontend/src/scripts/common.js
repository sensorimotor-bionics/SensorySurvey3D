export const uiPositions = Object.freeze({
    TOP: 0,
    BOTTOM: 1,
    LEFT: 2,
    RIGHT: 3
});

/**
 * Place the side and width bars on the right or left, and top or bottom 
 * respectively. Parameters can be changed to accomodate for handedness of 
 * participant
 * @param {number} rightleft - Determines if the sidebar will be on the right or 
 *      left side of the screen; 2 for left, 3 for right
 * @param {number} topbottom - Determines if the sidebar will be on the top or
 *      bottom of the screen; 0 for top, 1 for bottom
 * @returns {boolean}
 */
export function placeUI(rightleft, topbottom) {
    const sidebars = document.getElementsByClassName("sidebar");
    const widthbars = document.getElementsByClassName("widthbar");
    const threeDContainer = document.getElementById("3dContainer");

    const sidebarWidth = getComputedStyle(document.body).
                            getPropertyValue("--sideWidth");

    const style = window.getComputedStyle(document.body);

    sidebars[0].style.top = "0px";

    switch(rightleft) {
        case uiPositions.RIGHT:
            console.log("right!");
            sidebars[0].style.right = "0px";
            widthbars[0].style.right = sidebarWidth;
            threeDContainer.style.right = style.getPropertyValue("--sideWidth");
            sidebars[0].style.left = "auto";
            widthbars[0].style.left = "auto";
            threeDContainer.style.left = "auto";
            break;
        case uiPositions.LEFT:
            console.log("left!");
            sidebars[0].style.right = "auto";
            widthbars[0].style.right = "auto";
            threeDContainer.style.right = "auto";
            sidebars[0].style.left = "0px";
            widthbars[0].style.left = sidebarWidth;
            threeDContainer.style.left = style.getPropertyValue("--sideWidth");
            break;
        default:
            console.error("Receieved an invalid position for sidebar");
            return false;
    }

    switch(topbottom) {
        case uiPositions.TOP:
            widthbars[0].style.top = "0px";
            threeDContainer.style.top = style.getPropertyValue("--widthbarHeight");
            widthbars[0].style.bottom = "auto";
            threeDContainer.style.bottom = "auto";
            break;
        case uiPositions.BOTTOM:
            widthbars[0].style.top = "auto";
            threeDContainer.style.top = "auto";
            widthbars[0].style.bottom = "0px";
            threeDContainer.style.bottom = style.getPropertyValue("--widthbarHeight");
            break;
        default:
            console.error("Receieved an invalid position for widthbar");
            return false;
    }

    return true;
}

/**
 * Gets the element with the given ID, sets its display to "flex", then sets the
 * displays of all sidebarTab elements to "none". Enables switching between 
 * tabs.
 * @param {string} tabID - The ID of the element you want to switch to; 
 *      should be a sidebarTab element
 */
export function openSidebarTab(tabID) {
	var tab = document.getElementById(tabID);
    var tabContent = document.getElementsByClassName("sidebarTab");
    for (let i = 0; i < tabContent.length; i++) {
        tabContent[i].style.display = "none";
    }
    tab.style.display = "flex";
}

/**
 * Palette buttons are elements intended to change the behavior of the viewport
 * controls; this function changes the style of the palette button to reflect
 * that it is the one that is "active", while making every other button
 * "inactive"
 * @param {string} buttonID - The ID of the palette button element to be 
 *      activated
 */
export function activatePaletteButton(buttonID) {
    var imageButtons = document.getElementsByClassName("paletteButton");
	for (let i = 0; i < imageButtons.length; i++) {
        imageButtons[i].classList.remove("active")
    }
	document.getElementById(buttonID).classList.add("active");
}