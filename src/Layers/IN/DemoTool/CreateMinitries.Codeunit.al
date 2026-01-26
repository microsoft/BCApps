codeunit 101126 "Create Minitries"
{
    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('01', X01, false);
        InsertData('02', X02, false);
        InsertData('03', X03, false);
        InsertData('04', X04, false);
        InsertData('05', X05, false);
        InsertData('06', X06, false);
        InsertData('07', X07, false);
        InsertData('08', X08, false);
        InsertData('09', X09, false);
        InsertData('10', X10, false);
        InsertData('11', X11, false);
        InsertData('12', X12, false);
        InsertData('13', X13, false);
        InsertData('14', X14, false);
        InsertData('15', X15, false);
        InsertData('16', X16, false);
        InsertData('17', X17, false);
        InsertData('18', X18, false);
        InsertData('19', X19, false);
        InsertData('20', X20, false);
        InsertData('21', X21, false);
        InsertData('22', X22, false);
        InsertData('23', X23, false);
        InsertData('24', X24, false);
        InsertData('25', X25, false);
        InsertData('26', X26, false);
        InsertData('27', X27, false);
        InsertData('28', X28, false);
        InsertData('29', X29, false);
        InsertData('30', X30, false);
        InsertData('31', X31, false);
        InsertData('32', X32, false);
        InsertData('33', X33, false);
        InsertData('34', X34, false);
        InsertData('35', X35, false);
        InsertData('36', X36, false);
        InsertData('37', X37, false);
        InsertData('38', X38, false);
        InsertData('39', X39, false);
        InsertData('40', X40, false);
        InsertData('41', X41, false);
        InsertData('42', X42, false);
        InsertData('43', X43, false);
        InsertData('44', X44, false);
        InsertData('45', X45, false);
        InsertData('46', X46, false);
        InsertData('47', X47, false);
        InsertData('48', X48, false);
        InsertData('49', X49, false);
        InsertData('50', X50, false);
        InsertData('51', X51, false);
        InsertData('52', X52, false);
        InsertData('53', X53, false);
        InsertData('54', X54, false);
        InsertData('55', X55, false);
        InsertData('56', X56, false);
        InsertData('57', X57, false);
        InsertData('99', X99, true);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        X01: Label 'Agriculture';
        X02: Label 'Atomic Energy';
        X03: Label 'Fertilizers';
        X04: Label 'Chemicals and Petrochemicals';
        X05: Label 'Civil Aviation and Tourism';
        X06: Label 'Coal';
        X07: Label 'Consumer Affairs, Food and Public Distribution';
        X08: Label 'Commerce and Textiles';
        X09: Label 'Environment and Forests and Ministry of Earth Science';
        X10: Label 'External Affairs and Overseas Indian Affairs';
        X11: Label 'Finance';
        X12: Label 'Central Board of Direct Taxes';
        X13: Label 'Central Board of Excise and Customs';
        X14: Label 'Contoller of Aid Accounts and Audit';
        X15: Label 'Central Pension Accounting Office';
        X16: Label 'Food Processing Industries';
        X17: Label 'Health and Family Welfare';
        X18: Label 'Home Affairs and Development of North Eastern Region';
        X19: Label 'Human Resource Development';
        X20: Label 'Industry';
        X21: Label 'Information and Broadcasting';
        X22: Label 'Telecommunication and Information Technology';
        X23: Label 'Labour';
        X24: Label 'Law and Justice and Company Affairs';
        X25: Label 'Personnel, Public Grievances and Pesions';
        X26: Label 'Petroleum and Natural Gas';
        X27: Label 'Plannning, Statistics and Programme Implementation';
        X28: Label 'Power';
        X29: Label 'New and Renewable Energy';
        X30: Label 'Rural Development and Panchayati Raj';
        X31: Label 'Science And Technology';
        X32: Label 'Space';
        X33: Label 'Steel';
        X34: Label 'Mines';
        X35: Label 'Social Justice and Empowerment';
        X36: Label 'Tribal Affairs';
        X37: Label 'D/o Commerce (Supply Division)';
        X38: Label 'Shipping and Road Transport and Highways';
        X39: Label 'Urban Development, Urban Employment and Poverty Alleviation';
        X40: Label 'Water Resources';
        X41: Label 'President''s Secretariat';
        X42: Label 'Lok Sabha Secretariat';
        X43: Label 'Rajya Sabha secretariat';
        X44: Label 'Election Commission';
        X45: Label 'Ministry of Defence (Controller General of Defence Accounts)';
        X46: Label 'Ministry of Railways';
        X47: Label 'Department of Posts';
        X48: Label 'Department of Telecommunications';
        X49: Label 'Andaman and Nicobar Islands Administration   ';
        X50: Label 'Chandigarh Administration';
        X51: Label 'Dadra and Nagar Haveli';
        X52: Label 'Goa, Daman and Diu';
        X53: Label 'Lakshadweep';
        X54: Label 'Pondicherry Administration';
        X55: Label 'Pay and Accounts Officers (Audit)';
        X56: Label 'Ministry of Non-conventional energy sources ';
        X57: Label 'Government Of NCT of Delhi ';
        X99: Label 'Others';




    procedure InsertMiniAppData()
    begin
        AddMinistryForMini();
    end;

    local procedure AddMinistryForMini()
    begin
        DemoDataSetup.Get();
        InsertData('01', X01, false);
        InsertData('02', X02, false);
        InsertData('03', X03, false);
        InsertData('04', X04, false);
        InsertData('05', X05, false);
        InsertData('06', X06, false);
        InsertData('07', X07, false);
        InsertData('08', X08, false);
        InsertData('09', X09, false);
        InsertData('10', X10, false);
        InsertData('11', X11, false);
        InsertData('12', X12, false);
        InsertData('13', X13, false);
        InsertData('14', X14, false);
        InsertData('15', X15, false);
        InsertData('16', X16, false);
        InsertData('17', X17, false);
        InsertData('18', X18, false);
        InsertData('19', X19, false);
        InsertData('20', X20, false);
        InsertData('21', X21, false);
        InsertData('22', X22, false);
        InsertData('23', X23, false);
        InsertData('24', X24, false);
        InsertData('25', X25, false);
        InsertData('26', X26, false);
        InsertData('27', X27, false);
        InsertData('28', X28, false);
        InsertData('29', X29, false);
        InsertData('30', X30, false);
        InsertData('31', X31, false);
        InsertData('32', X32, false);
        InsertData('33', X33, false);
        InsertData('34', X34, false);
        InsertData('35', X35, false);
        InsertData('36', X36, false);
        InsertData('37', X37, false);
        InsertData('38', X38, false);
        InsertData('39', X39, false);
        InsertData('40', X40, false);
        InsertData('41', X41, false);
        InsertData('42', X42, false);
        InsertData('43', X43, false);
        InsertData('44', X44, false);
        InsertData('45', X45, false);
        InsertData('46', X46, false);
        InsertData('47', X47, false);
        InsertData('48', X48, false);
        InsertData('49', X49, false);
        InsertData('50', X50, false);
        InsertData('51', X51, false);
        InsertData('52', X52, false);
        InsertData('53', X53, false);
        InsertData('54', X54, false);
        InsertData('55', X55, false);
        InsertData('56', X56, false);
        InsertData('57', X57, false);
        InsertData('99', X99, true);
    end;

    procedure InsertData(Code: Code[3]; Name: Text[150]; Other: Boolean)
    var
        Ministry: Record Ministry;
    begin
        Ministry.Init();
        Ministry.Validate(Code, Code);
        Ministry.Validate(Name, Name);
        Ministry.Validate("Other Ministry", Other);
        Ministry.Insert();
    end;
}