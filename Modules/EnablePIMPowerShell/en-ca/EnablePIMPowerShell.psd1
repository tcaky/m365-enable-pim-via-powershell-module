$MsgTable = Data {
    #culture="en-ca"
    ConvertFrom-StringData @'
    WhichRole = Which role would you like to activate?
    CurrentlyActive = -= (Currently Active) =-
    Refresh = ''R/r'' to refresh without activating
    Choice = Which would you like to activate? (''Q/q'' to quit without activating)
    ActivationSuccess = Activation successful
    ActivationFail = Activation failed, please ensure you have the rights to access these permissions
    OpitionNotInChoices01 = ''{0}''  not within allowable choices
    OpitionNotInChoices02 = Hit enter key to continue
    EnterToContinue = Hit enter key to continue
'@
}