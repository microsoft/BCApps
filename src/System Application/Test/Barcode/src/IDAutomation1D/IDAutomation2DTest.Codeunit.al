// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Text;

using System.Text;

codeunit 135059 "IDAutomation 2D Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        CannotFindBarcodeEncoderErr: Label 'Provider IDAutomation 2D Barcode Provider: 2D Barcode symbol encoder Unsupported Barcode Symbology is not implemented by this provider!', comment = '%1 Provider Caption, %2 = Symbology Caption';

    [Test]
    procedure TestEncodingWithUnsupportedSymbology()
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
    begin
        // [Scenario] Encoding with unsupported barcode symbology yields an error

        GenericBarcodeTestHelper.Encode2DFontFailureTest(/* input */'A1234B', Enum::"Barcode Symbology 2D"::"Unsupported Barcode Symbology", /* expected error */CannotFindBarcodeEncoderErr);
        GenericBarcodeTestHelper.Encode2DFontFailureTest(/* input */'&&&&&&', Enum::"Barcode Symbology 2D"::"Unsupported Barcode Symbology", /* expected error */CannotFindBarcodeEncoderErr);
        GenericBarcodeTestHelper.Encode2DFontFailureTest(/* input */'(A&&&&&&A)', Enum::"Barcode Symbology 2D"::"Unsupported Barcode Symbology", /* expected error */CannotFindBarcodeEncoderErr);
    end;


    [Test]
    procedure TestAztecEncoding();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
        TextBuilder: TextBuilder;
    begin
        // [Scenario] Encoding a text using Codabar symbology yields the correct result
        TextBuilder.AppendLine(' AHFPAOILMHNCNOJOIDFLFHIDBDAHFCNDNHFDA ');
        TextBuilder.AppendLine(' NIFHDDGMDFBGJNGAKMFDFGNJOGBEPFJCGKFJE ');
        TextBuilder.AppendLine(' JDFHINKLNPBOIDLOFHFNHBDMLKJFGKNONPFMA ');
        TextBuilder.AppendLine(' GEFJMMFCPPMAAHEFFFFFFFEHAHNJNFLPJLFKA ');
        TextBuilder.AppendLine(' NHFGMHICBCBCAPAPAHFHAPAPACFHMGBCADFHA ');
        TextBuilder.AppendLine(' HIFNBJEDPHGGAPBNFFFFFNBPAKDGAEJMDJFLF ');
        TextBuilder.AppendLine(' IMFBDJBIMKKMHDCEECFBBFBCHFDDILIHDHFJC ');
        TextBuilder.AppendLine(' AFFOFJEJBOIAKKDPMKFMCJDHNIKIEMADANFBP ');
        TextBuilder.AppendLine(' ECFGFOBKJHEHICEHBDFPELFDEGIDAKIOFHFDJ ');
        TextBuilder.AppendLine(' PHHHPHPPHHHHPHHPPHHPHPHHPHPPHHHHHPHPH ');

        GenericBarcodeTestHelper.Encode2DFontTest(/* input */' ~!"#$%&\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}', Enum::"Barcode Symbology 2D"::Aztec, /* expected result */ TextBuilder.ToText());
    end;

    [Test]
    procedure TestDataMatrixEncoding();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
        TextBuilder: TextBuilder;
    begin
        // [Scenario] Encoding a text using Codabar symbology yields the correct result
        TextBuilder.AppendLine('AMAMCPDNFNGIGPAPAPCKAKHNFPEOAJCJDPGKBIHK ');
        TextBuilder.AppendLine('ALJPFNPEKGJNAHLOLNMKAFEGJJGBLFOLHKLLIDPK ');
        TextBuilder.AppendLine('AGJENGGNNMMMPNOHIPIKANCBJHOEBACGCNHJLFOK ');
        TextBuilder.AppendLine('AJBNJMFADFOFIHJNGBJKAFGNAAGFFEILEPNMBLFK ');
        TextBuilder.AppendLine('AMEAGEMGAOIKCIKGCEAKAEAGACCEKCOIAMOACAIK ');
        TextBuilder.AppendLine('AMDJENCOBKCNCPANBNGKALELGLCKHNGOBNFOFNFK ');
        TextBuilder.AppendLine('ADGHAKGNKFIEIDDIGHNKAGDCEDFKIBALIGAKPLIK ');
        TextBuilder.AppendLine('AOCNIHAMJDFLBFLIPOGKAGOPPPHBJODABDHBHFPK ');
        TextBuilder.AppendLine('AFAFIHAKNKAEIKJBDEGKAGEGDANJPBKIOJKAFHBK ');
        TextBuilder.AppendLine('AGEIOEKEGGOOKKAEOAOKAKIMIOKKGIGMMOAMCMIK ');

        GenericBarcodeTestHelper.Encode2DFontTest(/* input */' ~!"#$%&\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}', Enum::"Barcode Symbology 2D"::"Data Matrix", /* expected result */ TextBuilder.ToText());
    end;

    [Test]
    procedure TestMaxiCodeEncoding();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
        TextBuilder: TextBuilder;
    begin
        // [Scenario] Encoding a text using Codabar symbology yields the correct result
        TextBuilder.AppendLine('570716570663445472566504771554');
        TextBuilder.AppendLine('NT0TNS0SPRNTRTORPQOQNR0RTTTQO0');
        TextBuilder.AppendLine('263627377300372130235647773405');
        TextBuilder.AppendLine('N0TTSQNS00QS00E00000000SPRORPO');
        TextBuilder.AppendLine('01112000000000V000000030213154');
        TextBuilder.AppendLine('POOONP0QO00000W00000P00PNO0OR0');
        TextBuilder.AppendLine('23334000000000X000000050415101');
        TextBuilder.AppendLine('QPROQOTN00P000p00P0000SNT0S0NO');
        TextBuilder.AppendLine('770717263627001001110161542760');
        TextBuilder.AppendLine('SSSOSSSPNS0RRPTTNQSRPQRRNRTS0O');
        TextBuilder.AppendLine('523461352642775657643336605360');

        GenericBarcodeTestHelper.Encode2DFontTest(/* input */' ~!"#$%&\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}', Enum::"Barcode Symbology 2D"::"Maxi Code", /* expected result */ TextBuilder.ToText());
    end;

    [Test]
    procedure TestPDF417Encoding();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
        TextBuilder: TextBuilder;
    begin
        // [Scenario] Encoding a text using Codabar symbology yields the correct result
        TextBuilder.AppendLine('7777777707070700077763434205557310772600257305453307712146733156250077734135710565510744335406433677307763316543156244070133402623206110776166250673311207662413545057464077636342025573300777777707000707007 ');
        TextBuilder.AppendLine('7777777707070700077747073755454260735750327751043307217132641101164077724127037551120761701337275333107613146626500172072375311465314500773661641471133107221413037335222077747073351467440777777707000707007 ');
        TextBuilder.AppendLine('7777777707070700076360354600755510760070232615512207521153277221776076237450206613720762344705533402207666215271007575073335166612774300767316404023443307202371306722661071713767625576310777777707000707007 ');
        TextBuilder.AppendLine('7777777707070700073612047725551330777315205365512307761454407513306071372226521335410712273764247611107572227207177501071362373130721100703222634253310007473663342033550076342017661177540777777707000707007 ');
        TextBuilder.AppendLine('4444444404040400040400000404000000400040044440444404404044000444000040004404400400000400440444000440004004000000400400040440004400004000400040004400440004400440004000004040400000400400000444444404000404004 ');

        GenericBarcodeTestHelper.Encode2DFontTest(/* input */' ~!"#$%&\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}', Enum::"Barcode Symbology 2D"::PDF417, /* expected result */ TextBuilder.ToText());
    end;


    [Test]
    procedure TestQRCodeEncoding();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
        TextBuilder: TextBuilder;
    begin
        // [Scenario] Encoding a text using Codabar symbology yields the correct result
        TextBuilder.AppendLine('AHEEEHAPGMIOBKGOGMBIKCJENOAEEJOAPPAHEEEHA ');
        TextBuilder.AppendLine('BNFFFNBPAKNGADNHAOMCMOMPJPIOBGNDJPBNFFFNB ');
        TextBuilder.AppendLine('AIPKGNFHHDIFAENIIEHPKCJBIJBJMECCOAFDBCLOB ');
        TextBuilder.AppendLine('PJFAJKFMAPBHNGGNIKOAGOGEJDKBAIJHMBJFKJPDF ');
        TextBuilder.AppendLine('FEEMDIFCPFBHLJFKPDJPFEFIGPJBLOMCPPKMJOLII ');
        TextBuilder.AppendLine('MMDAJDFIAEEELNNOBOJKGMJMFPNEJGMKEIKCLMFMA ');
        TextBuilder.AppendLine('PDOGCIFACLBPPAMBLEGOJAKBCJAIOGDPABNBBPNPI ');
        TextBuilder.AppendLine('LPOJHOFHOIOGBMCHBINDJOHHGBLACIIHOCIGIDNCF ');
        TextBuilder.AppendLine('EFNFNNEHBAMPPIHPOEKHHDGBFPIFBIPGAHFHAMLJJ ');
        TextBuilder.AppendLine('APBBBPAPHFMPIKCHIIELEOEMHHAFKAPGAFHFHKDGI ');
        TextBuilder.AppendLine('HHHHHHHPHHPHHHHHHPHPPHPHHPHPPHHHHPHPHPPHP ');

        GenericBarcodeTestHelper.Encode2DFontTest(/* input */' ~!"#$%&\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}', Enum::"Barcode Symbology 2D"::"QR-Code", /* expected result */ TextBuilder.ToText());
    end;

}