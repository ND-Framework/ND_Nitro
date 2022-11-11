$(function() {
    window.addEventListener("message", function(event) {
        const item = event.data;
        if (item.type == "status") {
            if (item.display) {
                $(".bar").fadeIn();
            } else {
                $(".bar").fadeOut();
            };
        };

        if (item.type == "nosLevel") {
            $(".nos").css("width", item.nos + "%");
        };
        if (item.type == "purgeLevel") {
            $(".purge").css("width", item.purge + "%");
        };
    });
});