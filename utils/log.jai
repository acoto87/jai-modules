LogSeverity :: enum u8 {
    Critical;
    Error;
    Warning;
    Info;
    Debug;
}

LoggerData :: struct {
    severity := LogSeverity.Error;
    printTime := true;
    printSeverity := true;
    printLocation := true;
    printFullFilePath := false;
}

initLogger :: (data: *LoggerData) {
    context.logger_data = data;
}

logDebug :: #bake_arguments log(severity = LogSeverity.Debug);
logInfo :: #bake_arguments log(severity = LogSeverity.Info);
logWarning :: #bake_arguments log(severity = LogSeverity.Warning);
logError :: #bake_arguments log(severity = LogSeverity.Error);
logCritical :: #bake_arguments log(severity = LogSeverity.Critical);

log :: inline (severity: LogSeverity, formatString: string, args: .. Any, loc := #caller_location) {
    loggerData := cast(*LoggerData) context.logger_data;
    if (loggerData == null) {
        return;
    }

    if (severity > loggerData.severity) {
        return;
    }

    builder: StringBuilder;
    defer freeBuffers(*builder);

    if (loggerData.printTime) {
        t := time(null);
        timeInfo := localtime(*t);

        printToBuilder(*builder, "[%:%:%]",
            formatInt(timeInfo.hour, minimum_digits = 2),
            formatInt(timeInfo.min, minimum_digits = 2),
            formatInt(timeInfo.sec, minimum_digits = 2));
    }

    if (loggerData.printSeverity) {
        severityStr: string;

        if severity == {
            case LogSeverity.Critical; severityStr = "CRITICAL";
            case LogSeverity.Error;    severityStr = "ERROR";
            case LogSeverity.Warning;  severityStr = "WARNING";
            case LogSeverity.Info;     severityStr = "INFO";
            case LogSeverity.Debug;    severityStr = "DEBUG";
            case;                      severityStr = "UNKNOWN";
        }

        printToBuilder(*builder, "[%] ", severityStr);
    }

    if (loggerData.printLocation) {
        file := ifx loggerData.printFullFilePath
            then loc.fully_pathed_filename
            else _getFileName(loc.fully_pathed_filename);
        line := loc.line_number;
        printToBuilder(*builder, "[%:%] ", file, line);
    }

    printToBuilder(*builder, formatString, ..args);

    finalMessage := builderToString(*builder);

    info: Log_Info;
    info.location = loc;
    info.user_flags = cast(u32) severity;

    context.logger(finalMessage, context.logger_data, info);
}

#scope_file

_getFileName :: (filePath: string) -> string {
    index := 0;
    for i : range(0, filePath.count) {
        if (filePath[i] == #char "/" || filePath[i] == #char "\\") {
            index = i;
        }
    }

    result: string = ---;
    result.count = filePath.count - index - 1;
    result.data = filePath.data + index + 1;
    return result;
}
