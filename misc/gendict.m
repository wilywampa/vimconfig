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
        try
            gendictvar(fid, vars{i});
        catch ME
            if !strfind(ME.message, 'scalar cannot be indexed with {')
                rethrow(ME);
            end
        end
    end

    fclose(fid);

    if isunix
        system(['sort ' dict ' -o ' dict ' >& /dev/null']);
    end

function gendictvar(fid, var_in)

    printvar(fid, var_in);

    if isstruct(evalin('base', var_in))
        gendictstruct(fid, var_in);
    end

    if iscell(evalin('base', var_in))
        gendictcell(fid, var_in);
    end

function gendictstruct(fid, var_in)

    fields = fieldnames(evalin('base', var_in));
    hasStringFields = 0;

    for j = 1:length(fields)
        if strfind(fields{j}, '.')
            printvar(fid, [var_in '.(''' fields{j} ''')']);
            hasStringFields = 1;
        else
            printvar(fid, [var_in '.' fields{j}]);
            try %#ok
                var = evalin('base', [var_in '.' fields{j}]);
                if isstruct(var)
                    gendictstruct(fid, [var_in '.' fields{j}]);
                end
            end
        end
    end

    if hasStringFields
        fprintf(fid, [var_in '.(''\n']);
    end

function gendictcell(fid, var_in)

    for i = 1:evalin('base', ['numel(' var_in ')'])
        gendictvar(fid, [var_in '{' num2str(i) '}']);
    end

function str = sizestr(varnamestr)

    try
        var = evalin('base', varnamestr);
        sizein = size(var);
        str = strtrim(sprintf('%d ', sizein));
        str = strrep(str, ' ', 'x');
    catch
        str = '? ?';
    end
    return

function printvar(fid, varnamestr)

    try
        var = evalin('base', varnamestr);
        classstr = class(var);
        fprintf(fid, [varnamestr ' ' sizestr(varnamestr) ' ' classstr '\n']);
    catch %#ok<CTCH>
        fprintf(fid, [varnamestr ' ' sizestr(varnamestr) '\n']);
    end
