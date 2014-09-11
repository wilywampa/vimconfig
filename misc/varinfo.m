function [] = varinfo(varstr)

    var = evalin('base', varstr);
    str = strtrim(sprintf('%d ', size(var)));
    str = strrep(str, ' ', 'x');
    fprintf('%s %s\n', str, class(var))
