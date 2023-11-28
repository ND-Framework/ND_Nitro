const bar = document.querySelectorAll(".bar");
const nos = document.querySelector(".nos");
const purge = document.querySelector(".purge");

function fadeIn(element) {
    element.style.display = "block";
}

function fadeOut(element) {
    element.style.display = "none";
}

function setStatus(status) {
    return status ? fadeIn(bar) : fadeOut(bar);
}

window.addEventListener("message", function(event) {
    const item = event.data;

    if (item.type === "status") {
        setStatus(item.display);
    }

    if (item.type === "nosLevel") {
        nos.style.width = `${item.nos}%`
    }

    if (item.type === "purgeLevel") {
        purge.style.width = `${item.purge}%`
    }
});
