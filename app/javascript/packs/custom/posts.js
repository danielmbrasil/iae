if ($('.pagination')) {
  $(window).scroll(function() {
    url = $('.pagination .next_page a').attr('href');

    if (url && $(window).scrollTop() > $(document).height() - $(window).height() - 150) {
      $('.pagination').html('<div class="loader"  width="70" height="70"/>')
      $.getScript(url)
    }
  });
}

// store scroll position on reload
document.addEventListener("DOMContentLoaded", function (event) {
  var scrollpos = sessionStorage.getItem('scrollpos');
  if (scrollpos) {
      window.scrollTo(0, scrollpos);
      sessionStorage.removeItem('scrollpos');
  }
});

window.addEventListener("beforeunload", function (e) {
  sessionStorage.setItem('scrollpos', window.scrollY);
});
