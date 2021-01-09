LogSeverity :: enum {
    Critical;
    Error;
    Warning;
    Info;
    Debug;
}

initLog :: (severity: LogSeverity) {
    _severity = severity;
}

logDebug :: inline (formatString: string, args: .. Any, loc := #caller_location) {
    _logInternal(LogSeverity.Debug, loc.fully_pathed_filename, loc.line_number, formatString, args);
}

logInfo :: inline (formatString: string, args: .. Any, loc := #caller_location) {
    _logInternal(LogSeverity.Info, loc.fully_pathed_filename, loc.line_number, formatString, args);
}

logWarning :: inline (formatString: string, args: .. Any, loc := #caller_location) {
    _logInternal(LogSeverity.Warning, loc.fully_pathed_filename, loc.line_number, formatString, args);
}

logError :: inline (formatString: string, args: .. Any, loc := #caller_location) {
    _logInternal(LogSeverity.Error, loc.fully_pathed_filename, loc.line_number, formatString, args);
}

logCritical :: inline (formatString: string, args: .. Any, loc := #caller_location) {
    _logInternal(LogSeverity.Critical, loc.fully_pathed_filename, loc.line_number, formatString, args);
}

#scope_file

_severity := LogSeverity.Error;

_logInternal :: (severity: LogSeverity, file: string, line: s64, formatString: string, args: .. Any) {
    if (severity > _severity) {
        return;
    }

    t := time(null);
    timeInfo := localtime(*t);

    severityStr: string;

    if severity == {
        case LogSeverity.Critical; severityStr = "CRITICAL";
        case LogSeverity.Error;    severityStr = "ERROR";
        case LogSeverity.Warning;  severityStr = "WARNING";
        case LogSeverity.Info;     severityStr = "INFO";
        case LogSeverity.Debug;    severityStr = "DEBUG";
        case;                      severityStr = "UNKOWN";
    }

    fileName := _getFileName(file);

    builder: StringBuilder;
    defer freeBuffers(*builder);

    printToBuilder(*builder, "[%:%:%]", timeInfo.hour, timeInfo.min, timeInfo.sec);
    printToBuilder(*builder, "[%:(%)]", fileName, line);
    printToBuilder(*builder, " %", formatString, args);

    message := builderToString(*builder);
    context.logger(message, severityStr, Log_Mode.EVERYDAY, context.logger_data);
}

_getFileName :: (filePath: string) -> string {
    index := 0;
    for i : 0..filePath.count-1 {
        if (filePath[i] == #char "/" || filePath[i] == #char "\\") {
            index = i;
        }
    }

    result: string = ---;
    result.count = filePath.count - index - 1;
    result.data = filePath.data + index + 1;
    return result;
}
