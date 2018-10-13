/*
* Scripts.js
* Station Controller
*
* Created by Mitchell Sweet on 10/11/18
* Copyright © 2018 Mitchell Sweet. All rights reserved.
*/

$(document).scroll(function() {
	var y = $(this).scrollTop();
	if (y > 300) {
		$('#navbar').fadeIn();
	} else {
		$('#navbar').fadeOut();
	}
});

function scrollToTop(scrollDuration) {
    var scrollStep = -window.scrollY / (scrollDuration / 15),
        scrollInterval = setInterval(function(){
        if ( window.scrollY != 0 ) {
            window.scrollBy( 0, scrollStep );
        }
        else clearInterval(scrollInterval); 
    },15);
}