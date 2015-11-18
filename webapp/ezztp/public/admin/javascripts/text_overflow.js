$(function() {
    var count = 5;
    $('.text_overflow').each(function() {
        var thisText = $(this).text();
        var textArray = thisText.split('\n');
        var textLines = textArray.length;
        if (textLines > count) {
            var showText = textArray.slice(0, count).join("\n");
            var hideText = textArray.slice(count).join("\n");
            var insertText = showText;
            insertText += '<span class="more_text">' + "\n" + hideText + '</span>';
            insertText += '<span class="omit">\n...</span>';
            insertText += '<a href="#" class="collapse_btn" style="float: right">&nbsp;collapse</a>';
            insertText += '<a href="#" class="more_btn" style="float: right">&nbsp;more</a>';
            $(this).html(insertText);
        }
    });
    $('.text_overflow .more_text').hide();
    $('.text_overflow .collapse_btn').hide();
    $('.text_overflow .more_btn').click(function() {
        $(this).hide()
            .prev('.collapse_btn').show()
            .prev('.omit').hide()
            .prev('.more_text').show();
        return false;
    });
    $('.text_overflow .collapse_btn').click(function() {
        $(this).hide()
            .next('.more_btn').show()
            .prev('.collapse_btn').prev('.omit').show()
            .prev('.more_text').hide();
        return false;
    });
});
