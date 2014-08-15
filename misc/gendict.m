function gendict

    vars = evalin('base', 'who');

    if ismac
        dict = '~/Documents/MATLAB/dict.m';
    elseif ispc
        dict = [getenv('USERPROFILE') '\Documents\MATLAB\dict.m'];
    else
        dict = '~/MATLAB/dict.m';
    end
    fid = fopen(dict, 'w');

    for i = 1:length(vars)
        printvar(fid, vars{i});

        if isstruct(evalin('base', vars{i}))
            gendictstruct(fid, vars{i});
        end
    end

    fclose(fid);

    if isunix
        system(['sort ' dict ' -o ' dict ' >& /dev/null']);
    end

function gendictstruct(fid, var_in)

    fields = fieldnames(evalin('base', var_in));
    hasStringFields = 0;

    for j = 1:length(fields)
        if findstr(fields{j}, '.')
            printvar(fid, [var_in '.(''' fields{j} ''')']);
            hasStringFields = 1;
        else
            printvar(fid, [var_in '.' fields{j}]);
            if evalin('base', ['exist(''' var_in '.' fields{j} ''')'])
                if isstruct(evalin('base', [var_in '.' fields{j}]))
                    gendictstruct(fid, [var_in '.' fields{j}]);
                end
            end
        end
    end

    if hasStringFields
        fprintf(fid, [var_in '.(''\n']);
    end

function str = sizestr(sizein)

    if nargin == 0
        str = '0';
    else
        str = strtrim(sprintf('%d ', sizein));
        str = strrep(str, ' ', 'x');
    end

    return

function printvar(fid, varnamestr)

    varinfo = evalin('base', ['whos(''' varnamestr ''')']); %#ok
    fprintf(fid, [varnamestr ' ' sizestr(varinfo.size) ' ' varinfo.class '\n']);
