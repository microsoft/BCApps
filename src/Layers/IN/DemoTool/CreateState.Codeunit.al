codeunit 120552 "Create State"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('AN', 'Andaman and Nicobar Islands', '35', '01');
        InsertData('AD', 'Andhra Pradesh', '37', '02');
        InsertData('AR', 'Arunachal Pradesh', '12', '03');
        InsertData('AS', 'Assam', '18', '04');
        InsertData('BR', 'Bihar', '10', '05');
        InsertData('CH', 'Chandigarh', '04', '06');
        InsertData('CG', 'Chattisgarh', '22', '33');
        InsertData('DN', 'Dadra and Nagar Haveli', '26', '07');
        InsertData('DD', 'Daman and Diu', '25', '08');
        InsertData('DL', 'Delhi', '07', '09');
        InsertData('GA', 'Goa', '30', '10');
        InsertData('GJ', 'Gujarat', '24', '11');
        InsertData('HR', 'Haryana', '06', '12');
        InsertData('HP', 'Himachal Pradesh', '02', '13');
        InsertData('JK', 'Jammu and Kashmir', '01', '14');
        InsertData('JH', 'Jharkhand', '20', '35');
        InsertData('KA', 'Karnataka', '29', '15');
        InsertData('KL', 'Kerala', '32', '16');
        InsertData('LA', 'Ladakh', '38', '37');
        InsertData('LD', 'Lakshadweep Islands', '31', '17');
        InsertData('MP', 'Madhya Pradesh', '23', '18');
        InsertData('MH', 'Maharashtra', '27', '19');
        InsertData('MN', 'Manipur', '14', '20');
        InsertData('ML', 'Meghalaya', '17', '21');
        InsertData('MZ', 'Mizoram', '15', '22');
        InsertData('NL', 'Nagaland', '13', '23');
        InsertData('OD', 'Odisha', '21', '24');
        InsertData('PY', 'Pondicherry', '34', '25');
        InsertData('PB', 'Punjab', '03', '26');
        InsertData('RJ', 'Rajasthan', '08', '27');
        InsertData('SK', 'Sikkim', '11', '28');
        InsertData('TN', 'Tamil Nadu', '33', '29');
        InsertData('TS', 'Telangana', '36', '36');
        InsertData('TR', 'Tripura', '16', '30');
        InsertData('UP', 'Uttar Pradesh', '09', '31');
        InsertData('UK', 'Uttarakhand', '05', '34');
        InsertData('WB', 'West Bengal', '19', '32');


    end;

    var
        state: Record State;
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData("No.": Code[20]; Descrip: Text[50]; StateGSTRegNo: Code[10]; ETDSTCS: Code[20])
    begin
        DemoDataSetup.Get();
        state.Init();
        state.Code := "No.";
        state.Description := Descrip;
        state."State Code (GST Reg. No.)" := StateGSTRegNo;
        state."State Code for eTDS/TCS" := ETDSTCS;
        state.Insert();
    end;
}

