function forEachQSA(a, b)
{
    Array.prototype.forEach.call(document.querySelectorAll(a), b)
}

function replaceImageWithAlt(a, b, c)
{
    b = b || "", c = c || "", forEachQSA(a, function(a)
    {
        var d = document.createTextNode(a.alt ? b + a.alt + c : "");
        a.parentElement.replaceChild(d, a)
    })
}
location.search.indexOf("vo-guide") > -1 && (document.body.className += "vo-guide");
