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
        TextBuilder.AppendLine('AMAMCPDNFNGNCLAPCPCKAPDJFPGOBICNFIBKBMAK ');
        TextBuilder.AppendLine('ALJPFNPFODINDPDPPJNKAFGPAIGFLHMMINPLIDHK ');
        TextBuilder.AppendLine('AGJENHLLHEEBDBOHCHBKAMCFLFMEJBGCCMGOJGOK ');
        TextBuilder.AppendLine('ALGLJEFBHBOFKOAOGFJKAHENIFCBFEILCNECKDFK ');
        TextBuilder.AppendLine('ACAECAMGKGAKCMIEEEIKAEECACCEOEKKKIKEECIK ');
        TextBuilder.AppendLine('AODJEPAOBLGJCPCMAOGKAPEKGKHJBMDJELCMEPAK ');
        TextBuilder.AppendLine('AFAHIPCJKFKMBCDMGHNKACFPFCKDKFFCCPJOPCLK ');
        TextBuilder.AppendLine('APGJIHKFACFPBFLIPOMKAJDKHEGJKLCJOMGDDJMK ');
        TextBuilder.AppendLine('AFCNBGAONKAEIKICELBKAFPMOOLAOEMCOEIPJPBK ');
        TextBuilder.AppendLine('AGEMOEKEGGOOGCAEGEOKAGGIEGKCCIEMGGIAKAIK ');

        GenericBarcodeTestHelper.Encode2DFontTest(/* input */' ~!"#$%&\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}', Enum::"Barcode Symbology 2D"::"Data Matrix", /* expected result */ TextBuilder.ToText());
    end;

    [Test]
    procedure TestMaxiCodeEncoding();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
        TextBuilder: TextBuilder;
    begin
        // [Scenario] Encoding a text using Codabar symbology yields the correct result
        TextBuilder.AppendLine('570716570663445472566504771574');
        TextBuilder.AppendLine('0TNS0SPRPRNTRTORPQOQNR0RTTTQ00');
        TextBuilder.AppendLine('172636273773003721302356477715');
        TextBuilder.AppendLine('TTSQNS0S00QS00E0000000PRORPQN0');
        TextBuilder.AppendLine('10011100000000V000000020302165');
        TextBuilder.AppendLine('OONP0P0QO00000W00000P0NO0OPNSO');
        TextBuilder.AppendLine('32233300000000X000000040504145');
        TextBuilder.AppendLine('ROQOTNSN00P000p00P0000T0S0RNQ0');
        TextBuilder.AppendLine('437707172636270010010601066261');
        TextBuilder.AppendLine('NRSTPTQRSPTTRSPST0TTRSSRQSPPT0');
        TextBuilder.AppendLine('476632347410576327000463646664');

        GenericBarcodeTestHelper.Encode2DFontTest(/* input */' ~!"#$%&\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}', Enum::"Barcode Symbology 2D"::"Maxi Code", /* expected result */ TextBuilder.ToText());
    end;

    [Test]
    procedure TestPDF417Encoding();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
        TextBuilder: TextBuilder;
    begin
        // [Scenario] Encoding a text using Codabar symbology yields the correct result
        TextBuilder.AppendLine('7777777707070700077763434205557310772610256215553207313016233153215077735034611564500766027416731744007673325640246374072211510730237020745064362751102007553500547377457077636342025573300777777707000707007 ');
        TextBuilder.AppendLine('7777777707070700077747073755454260730741777714463007640751326314532072452145333060000726331654424556207406503722015113074200633727423300736537401222411307007452266631732077747073351467440777777707000707007 ');
        TextBuilder.AppendLine('7777777707070700076360354600755510727741124777126607024112667204771072055720176731600767321464204537407630516000573112077134672771502320776603501073576407667274453730242071713767625576310777777707000707007 ');
        TextBuilder.AppendLine('7777777707070700073612047725551330773152152671112307263130510043130073622131503503310743366260306311007567322643427551070772762135220000747336224256710007437222646126555076342017661177540777777707000707007 ');
        TextBuilder.AppendLine('4444444404040400040400000404000000444044004044000004004440000444040040004404400004000440044404440044004000040044400444040040440000440000444044404000040004444040004004444040400000400400000444444404000404004 ');

        GenericBarcodeTestHelper.Encode2DFontTest(/* input */' ~!"#$%&\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}', Enum::"Barcode Symbology 2D"::PDF417, /* expected result */ TextBuilder.ToText());
    end;


    [Test]
    procedure TestQRCodeEncoding();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
        TextBuilder: TextBuilder;
    begin
        // [Scenario] Encoding a text using Codabar symbology yields the correct result
        TextBuilder.AppendLine('AHEEEHAPCNJGMIHBOFDEHGPDMAKNDKJODPAHEEEHA ');
        TextBuilder.AppendLine('BNFFFNBPMGAOBPICMGJKNDEGBHMPAOBKJPBNFFFNB ');
        TextBuilder.AppendLine('HKFCNAFBLNPGHOLMIDMLHFCAKOOPEFLPAOGIJHNAC ');
        TextBuilder.AppendLine('DNLNGDFFCDEHJADAFNKNBGGADNDKDNPJGLIBNFHIE ');
        TextBuilder.AppendLine('HCNLCJFMLKAOJGGIDOEPCCBLLFPEGEDLIPNGHAMIO ');
        TextBuilder.AppendLine('PCDDOAFEOFPFFNPKKNMOKLONPIACAHELEMDBDLLCC ');
        TextBuilder.AppendLine('FCLDKPFLIMGPEGFNIDCADIIHFHJCNDHBIKMEGJFEJ ');
        TextBuilder.AppendLine('FDAEOAFAGAPFMEOAPAAIDPBOOLPBHCHOIDPOGJKCD ');
        TextBuilder.AppendLine('MFFNFFEHABBHHBKFPCBLKDPAPKHDJPEDAHFHALFPD ');
        TextBuilder.AppendLine('APBBBPAPJHGDBHJNMONNOGIKBBFPJBJMAHGCCCNMJ ');
        TextBuilder.AppendLine('HHHHHHHPHPHPPPPPPHPHPHPHPHHPPPPPHHPHPHPHP ');

        GenericBarcodeTestHelper.Encode2DFontTest(/* input */' ~!"#$%&\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}', Enum::"Barcode Symbology 2D"::"QR-Code", /* expected result */ TextBuilder.ToText());
    end;

}