codeunit 132906 DeviceCardTest
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Device] [UI]
    end;

    var
        DeviceTable: Record Device;
        DeviceCardPage: TestPage "Device Card";
        DeviceAlreadyExistErr: Label 'already exists';
        Device002Txt: Label '10-12-12-12-AB';
        Device003Txt: Label '11-12-12-12-AB';
        Device004Txt: Label '12-12-12-12-AB';
        Device005Txt: Label '13-12-12-12-AB';
        ErrorStringCom001Err: Label 'Missing Expected error message: %1. \ Actual error recieved: %2.';
        RowNotfound001Err: Label 'The row does not exist on the TestPage.';
        ValidationError: Text;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InserDevices()
    begin
        AddDeviceHelper(Device002Txt);
        AddDeviceHelper(Device003Txt);
        AddDeviceHelper(Device004Txt);
        AddDeviceHelper(Device005Txt);

        DeviceCardPage.OpenEdit();
        DeviceCardPage.FindFirstField("MAC Address", Device002Txt);
        DeviceCardPage."MAC Address".AssertEquals(Device002Txt);
        DeviceCardPage.Close();

        DeviceCardPage.OpenEdit();
        DeviceCardPage.FindFirstField("MAC Address", Device003Txt);
        DeviceCardPage."MAC Address".AssertEquals(Device003Txt);
        DeviceCardPage.Close();

        DeviceCardPage.OpenEdit();
        DeviceCardPage.FindFirstField("MAC Address", Device004Txt);
        DeviceCardPage."MAC Address".AssertEquals(Device004Txt);
        DeviceCardPage.Close();

        DeviceCardPage.OpenEdit();
        DeviceCardPage.FindFirstField("MAC Address", Device005Txt);
        DeviceCardPage."MAC Address".AssertEquals(Device005Txt);
        DeviceCardPage.Close();

        DeviceTable.DeleteAll();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckDeviceAlreadyExists()
    begin
        AddDeviceHelper(Device002Txt);

        DeviceCardPage.OpenNew();
        DeviceCardPage."MAC Address".Value := Device002Txt;
        DeviceCardPage.OK().Invoke();

        if StrPos(DeviceCardPage.GetValidationError(), DeviceAlreadyExistErr) = 0 then begin
            ValidationError := DeviceCardPage.GetValidationError();
            DeviceCardPage.Close();
            Error(ErrorStringCom001Err, DeviceAlreadyExistErr, ValidationError);
        end;
        DeviceCardPage.Close();

        DeviceTable.DeleteAll();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeleteDeviceTest()
    var
        DeviceCardPage: TestPage "Device Card";
    begin
        // Test function property TransactionModel = autoRoolback
        // Doesn't work can not invoke the delete button on a page - workaround implemented - deleting the record directly in the table
        AddDeviceHelper(Device003Txt);

        DeviceCardPage.OpenEdit();
        DeviceCardPage.FindFirstField("MAC Address", Device003Txt);
        DeviceCardPage."MAC Address".AssertEquals(Device003Txt);
        DeviceCardPage.Close();
        // GETACTION is not getting the DELETE ID from the MetadataEditor bug 273002
        // DeviceCardPage.GETACTION(2000000152).Invoke();
        // DeviceCardPage.Close();}
        // Bug 273002 --Removed the UI handler until the bug is resolved."EventYesHandler"
        // Workaround deleting the Device from the table
        DeviceTable.SetFilter("MAC Address", Device003Txt);
        if DeviceTable.FindFirst() then
            DeviceTable.Delete();
        DeviceTable.SetRange("MAC Address");
        DeviceCardPage.Trap();
        DeviceCardPage.OpenView();
        asserterror DeviceCardPage.FindFirstField("MAC Address", Device003Txt);
        if GetLastErrorText <> RowNotfound001Err then begin
            DeviceTable.DeleteAll();
            ValidationError := GetLastErrorText;
            DeviceCardPage.Close();
            Error(ErrorStringCom001Err, RowNotfound001Err, ValidationError);
        end;
        DeviceTable.DeleteAll();
    end;

    [Normal]
    local procedure AddDeviceHelper(DeviceName: Text[250])
    begin
        DeviceCardPage.OpenNew();
        DeviceCardPage."MAC Address".Value := DeviceName;
        DeviceCardPage.Name.Value := 'xyz';
        DeviceCardPage."Device Type".Value := 'Limited';
        DeviceCardPage.Close();
    end;
}

