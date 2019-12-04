<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <script type="text/javascript">
    var JINDO = new Object();
    JINDO.xml2obj = function(xml) {
        var obj = {}, que = [], depth = 0;

        // attribute를 해석하기 위한 함수
        var parse_attr = function(oobj, str) {
            str.replace(/([^=\s]+)\s*=\s*"([^"]*)"/g, function(a0,a1,a2) {
                oobj[a1] = a2;
            });
        }

        // 주석, XML선언, 태그 사이 공백 등의 의미 없는 코드를 삭제
        xml = xml.replace(/<(\?|\!-)[^>]*>/g,'').replace(/>\s+</g, '><');

        // 하위 노드가 없는 태그는 하나의 닫힌 태그로 수정
        xml = xml.replace(/<([^!][^ >]+)(\s[^>]*)?><\/\1>/g, '<$1$2 />').replace(/^\s+|\s+$/g, '');

        // 함수 객체를 정규 표현식 처리의 인자로 줘서 iterator로 사용
        xml = xml.replace(/<\/?([^\!][^ >]*)(\s[^>]*)?>(<\/$1>|<\!\[CDATA\[(?:(.|\s)*?)\]\]>|[^<>]*)/g, function(a0,a1,a2,a3) {
            // IE에서 일치하는 내용이 없으면 undefined로 전달되므로
            // 빈 문자열로 변경해 다른 브라우저와의 호환성을 맞춤
            if (typeof a1 == 'undefined') a1 = '';
            if (typeof a2 == 'undefined') a2 = '';
            if (typeof a3 == 'undefined') a3 = '';

            if (a0.substr(1,1) == '/') { // 현재 태그가 닫는 태그라면,
                // 깊이를 1만큼 감소
                depth--;
            } else if (que.length == 0) { // 객체 큐에 객체가 없다면,
                que[depth] = obj; // 초기의 객체를 큐에 넣고
                parse_attr(obj, a2); // attribute를 해석
            } else {
                var k  = a1, o = {}, is_closed = false;

                is_closed = (a2.substr(-1,1) == '/');
                if (a3.length > 0 || is_closed) { // 텍스트 노드가 있다면
                    o = a3; // 추가할 객체는 문자열 객체

                    // CDATA라면 전달받은 그대로 리턴하고
                    // 그렇지 않다면 decode 해서 리턴
                    if (o.substr(0,9) == '<![CDATA[' && o.substr(-3,3) == ']]>') o = o.substring(9, o.length-3);
                    else o = o.replace(/</g, '<').replace(/>/g, '>').replace(/&/g, '&');
                }

                // 객체를 할당하기 전에 태그 이름이 이미 존재하는지 살펴보고
                // 이전에 존재하는 태그라면, 배열로 만든다. 이미 배열이라면 현재의 객체를 배열에 추가
                if (typeof que[depth][k] == 'undefined') {
                    que[depth][k] = o;
                } else {
                    var v = que[depth][k];
                    if (que[depth][k].constructor != Array) que[depth][k] = [v];
                    que[depth][k].push(o);
                }

                // attribute를 해석
                parse_attr(o, a2);

                if (!is_closed) que[++depth] = o;
            }

            return '';
        });

//         obj.filter(function(object) {
//             console.log(object["TypeCode"]);
//         });

        console.log(obj);

        return obj;
    }


    function xmlToJson(xml) {
        // Create the return object
        var obj = {};

        if (xml.nodeType == 1) { // element
            // do attributes
            if (xml.attributes.length > 0) {
            obj["@attributes"] = {};
                for (var j = 0; j < xml.attributes.length; j++) {
                    var attribute = xml.attributes.item(j);
                    obj["@attributes"][attribute.nodeName] = attribute.nodeValue;
                }
            }
        } else if (xml.nodeType == 3) { // text
            obj = xml.nodeValue;
        }

        // do children
        if (xml.hasChildNodes()) {
            for(var i = 0; i < xml.childNodes.length; i++) {
                var item = xml.childNodes.item(i);
                var nodeName = item.nodeName;
                if (typeof(obj[nodeName]) == "undefined") {
                    obj[nodeName] = xmlToJson(item);
                } else {
                    if (typeof(obj[nodeName].push) == "undefined") {
                        var old = obj[nodeName];
                        obj[nodeName] = [];
                        obj[nodeName].push(old);
                    }

                    obj[nodeName].push(xmlToJson(item));
                }
            }
        }

        return obj;
    };
    
    
    /**
     * 적용
     **/
    function fn_getXmlValue() {

        if(inputForm.fl_xml_file.value == "") {
            alert("XML파일을 선택하세요");
            return false;
        }
        
        gfn_showLoadingbar();

        inputForm.txt_IssueID.value            = "";
        inputForm.txt_Invoice_Date.value       = "";
        inputForm.txt_customer_regi.value      = "";
        inputForm.txt_customer_id.value        = "";
        inputForm.txt_customer_num.value       = "";
        inputForm.txt_customer_name.value      = "";
        inputForm.txt_customer_pay_group.value = "";
        inputForm.txt_CustomerSite_Code.value  = "";
        inputForm.txtAmount.value              = "";
        inputForm.hid_invoicer_detail.value    = "";
        inputForm.txt_Description.value        = "";

        var reader = new FileReader();
        reader.onload = function (e) {
            var data = e.target.result;
    
            var parser = new DOMParser();
            var xmlDoc = parser.parseFromString(data, "text/xml");
            
            //승인번호 설정
            var x = xmlDoc.getElementsByTagName("TaxInvoiceDocument");
            if(x.length == 0) {
                fn_procStopMsg("XML파일에서 승인번호가 검색되지 않았습니다. 파일내용을 확인 하세요");
                return false;
            }
    
            for(i = 0; i < x.length; i++) {
                inputForm.txt_IssueID.value      = x[i].getElementsByTagName("IssueID")[0].childNodes[0].nodeValue;
                inputForm.txt_Invoice_Date.value = x[i].getElementsByTagName("IssueDateTime")[0].childNodes[0].nodeValue;
                if(x[i].getElementsByTagName("DescriptionText").length > 0 && x[i].getElementsByTagName("DescriptionText")[0].childNodes.length > 0)
                    inputForm.txt_Description.value  = x[i].getElementsByTagName("DescriptionText")[0].childNodes[0].nodeValue;
    
                //세금계산서 종류
                var y = x[i].getElementsByTagName("TypeCode");
                if(y.length == 0) {
                    inputForm.txt_type_code.value = "0101"; //없을 경우 기본으로 저장
                }
                else {
                    inputForm.txt_type_code.value = x[i].getElementsByTagName("TypeCode")[0].childNodes[0].nodeValue;
                }
    
                //영수/청구 구분
                var y = x[i].getElementsByTagName("PurposeCode");
                if(y.length == 0) {
                    inputForm.txt_purpose_code.value = "01"; //없을 경우 영수를 기본으로 저장
                }
                else {
                    inputForm.txt_purpose_code.value = x[i].getElementsByTagName("PurposeCode")[0].childNodes[0].nodeValue;
                }
            }
    
            //전자세금계산서-전표 매핑확인
            var rtMsg = fn_eatxMappingcheck(); 
            if(rtMsg != "") {
                fn_procStopMsg(rtMsg);
                return false;
            };
    
            //발행처 설정
            var x = xmlDoc.getElementsByTagName("InvoicerParty");
            if(x.length == 0) {
                fn_procStopMsg("XML파일에서 발행처가 검색되지 않았습니다. 파일내용을 확인 하세요");
                return false;
            }
    
            for(i = 0; i < x.length; i++) {
                inputForm.txt_customer_regi.value = x[i].getElementsByTagName("ID")[0].childNodes[0].nodeValue.substr(0, 3) + "-" + x[i].getElementsByTagName("ID")[0].childNodes[0].nodeValue.substr(3, 2) + "-" + x[i].getElementsByTagName("ID")[0].childNodes[0].nodeValue.substr(5, 5);
                inputForm.txt_invoicer_emp_name.value = x[i].getElementsByTagName("SpecifiedPerson")[0].getElementsByTagName("NameText")[0].childNodes[0].nodeValue;
    
                var y = x[i].getElementsByTagName("SpecifiedAddress");
                if(y.length != 0) {
                    var k = x[i].getElementsByTagName("SpecifiedAddress")[0].getElementsByTagName("LineOneText")[0].childNodes;
    
                    if(k.length != 0) {
                        inputForm.txt_invoicer_address.value = x[i].getElementsByTagName("SpecifiedAddress")[0].getElementsByTagName("LineOneText")[0].childNodes[0].nodeValue;
                    }
                }
    
                var y = x[i].getElementsByTagName("TypeCode");
                if(y.length >= 1) {
                    var k = x[i].getElementsByTagName("TypeCode")[0].childNodes;
    
                    if(k.length != 0) {
                        inputForm.txt_invoicer_fran_type.value = x[i].getElementsByTagName("TypeCode")[0].childNodes[0].nodeValue;
                    }
                }
    
                var y = x[i].getElementsByTagName("ClassificationCode");
                if(y.length >= 1) {
                    var k = x[i].getElementsByTagName("ClassificationCode")[0].childNodes;
    
                    if(k.length != 0) {
                        inputForm.txt_invoicer_fran_class.value = x[i].getElementsByTagName("ClassificationCode")[0].childNodes[0].nodeValue;
                    }
                }
    
                var k = x[i].getElementsByTagName("DefinedContact");
                if(k.length != 0) {
                    var y = x[i].getElementsByTagName("DefinedContact")[0].getElementsByTagName("URICommunication");
    
                    if(y.length != 0) {
                        var k = x[i].getElementsByTagName("DefinedContact")[0].getElementsByTagName("URICommunication")[0].childNodes;
    
                        if(k.length!== 0) {
                            inputForm.txt_invoicer_url.value = x[i].getElementsByTagName("DefinedContact")[0].getElementsByTagName("URICommunication")[0].childNodes[0].nodeValue;
                        }
                    }
                }
            }
            
            //공급자 설정
            var x = xmlDoc.getElementsByTagName("InvoiceeParty");
            if(x.length == 0) {
                fn_procStopMsg("XML파일에서 공급자가 검색되지 않았습니다. 파일내용을 확인 하세요");
                return false;
            }
    
            for(i = 0; i < x.length; i++) {
                inputForm.txt_invoicee_fran_num.value = x[i].getElementsByTagName("ID")[0].childNodes[0].nodeValue.substr(0, 3) + "-" + x[i].getElementsByTagName("ID")[0].childNodes[0].nodeValue.substr(3, 2) + "-" + x[i].getElementsByTagName("ID")[0].childNodes[0].nodeValue.substr(5, 5);
                inputForm.txt_invoicee_fran_name.value = x[i].getElementsByTagName("NameText")[0].childNodes[0].nodeValue;
    
                var y = x[i].getElementsByTagName("SpecifiedOrganization");
                if(y.length != 0) {
                    var k = x[i].getElementsByTagName("SpecifiedOrganization")[0].getElementsByTagName("BusinessTypeCode").length;
    
                    if(k != 0) {
                        inputForm.txt_invoicee_tax_id.value = x[i].getElementsByTagName("SpecifiedOrganization")[0].getElementsByTagName("BusinessTypeCode")[0].childNodes[0].nodeValue;
                    }
                }
    
                inputForm.txt_invoicee_emp_name.value = x[i].getElementsByTagName("SpecifiedPerson")[0].getElementsByTagName("NameText")[0].childNodes[0].nodeValue;
    
                var y = x[i].getElementsByTagName("SpecifiedAddress");
                if(y.length != 0) {
                    var k = x[i].getElementsByTagName("SpecifiedAddress")[0].getElementsByTagName("LineOneText")[0].childNodes;
    
                    if(k.length != 0) {
                        inputForm.txt_invoicee_address.value = x[i].getElementsByTagName("SpecifiedAddress")[0].getElementsByTagName("LineOneText")[0].childNodes[0].nodeValue;
                    }
                }
    
                var y = x[i].getElementsByTagName("TypeCode");
                if(y.length >= 1) {
                    inputForm.txt_invoicee_fran_type.value = x[i].getElementsByTagName("TypeCode")[0].childNodes[0].nodeValue;
                }
    
                var y = x[i].getElementsByTagName("ClassificationCode");
                if(y.length >= 1) {
                    inputForm.txt_invoicee_fran_class.value = x[i].getElementsByTagName("ClassificationCode")[0].childNodes[0].nodeValue;
                }
    
                var k = x[i].getElementsByTagName("PrimaryDefinedContact");
                if(k.length != 0) {
                    var y = x[i].getElementsByTagName("PrimaryDefinedContact")[0].getElementsByTagName("URICommunication");
    
                    if(y.length != 0) {
                        var k = x[i].getElementsByTagName("PrimaryDefinedContact")[0].getElementsByTagName("URICommunication")[0].childNodes;
    
                        if(k.length != 0) {
                            inputForm.txt_invoicee_url.value = x[i].getElementsByTagName("PrimaryDefinedContact")[0].getElementsByTagName("URICommunication")[0].childNodes[0].nodeValue;
                        }
                    }
                }
            }
    
            //수탁자 설정
            /*
            <위수탁 전자세금계산서 구분 CODE>
            0103    위수탁전자세금계산서
            0105    영세율위수탁전자세금계산서
            0203    수정위수탁전자세금계산서
            0205    수정영세율위수탁전자세금계산서
            0303    위수탁전자계산서
            0403    수정위수탁전자계산서
            */
            var txtTypeCode = inputForm.txt_type_code.value;
            if(txtTypeCode == "0103" || txtTypeCode == "0105" || txtTypeCode == "0203" || txtTypeCode == "0205" || txtTypeCode == "0303" || txtTypeCode == "0403") {
                
                var x = xmlDoc.getElementsByTagName("BrokerParty");
                if(x.length == 0) {
                    fn_procStopMsg("XML파일에서 수탁자가 검색되지 않았습니다. 파일내용을 확인 하세요");
                    return false;
                }
        
                for(i = 0; i < x.length; i++) {
                    inputForm.txt_broker_fran_num.value = x[i].getElementsByTagName("ID")[0].childNodes[0].nodeValue.substr(0, 3) + "-" + x[i].getElementsByTagName("ID")[0].childNodes[0].nodeValue.substr(3, 2) + "-" + x[i].getElementsByTagName("ID")[0].childNodes[0].nodeValue.substr(5, 5);
                    inputForm.txt_broker_fran_name.value = x[i].getElementsByTagName("NameText")[0].childNodes[0].nodeValue;
        
                    var y = x[i].getElementsByTagName("SpecifiedOrganization");
                    if(y.length != 0) {
                        var k = x[i].getElementsByTagName("SpecifiedOrganization")[0].getElementsByTagName("BusinessTypeCode").length;
        
                        if(k != 0) {
                            inputForm.txt_broker_tax_id.value = x[i].getElementsByTagName("SpecifiedOrganization")[0].getElementsByTagName("BusinessTypeCode")[0].childNodes[0].nodeValue;
                        }
                    }
        
                    inputForm.txt_broker_emp_name.value = x[i].getElementsByTagName("SpecifiedPerson")[0].getElementsByTagName("NameText")[0].childNodes[0].nodeValue;
        
                    var y = x[i].getElementsByTagName("SpecifiedAddress");
                    if(y.length != 0) {
                        var k = x[i].getElementsByTagName("SpecifiedAddress")[0].getElementsByTagName("LineOneText")[0].childNodes;
        
                        if(k.length != 0) {
                            inputForm.txt_broker_address.value = x[i].getElementsByTagName("SpecifiedAddress")[0].getElementsByTagName("LineOneText")[0].childNodes[0].nodeValue;
                        }
                    }
        
                    var y = x[i].getElementsByTagName("TypeCode");
                    if(y.length >= 1) {
                        inputForm.txt_broker_fran_type.value = x[i].getElementsByTagName("TypeCode")[0].childNodes[0].nodeValue;
                    }
        
                    var y = x[i].getElementsByTagName("ClassificationCode");
                    if(y.length >= 1) {
                        inputForm.txt_broker_fran_class.value = x[i].getElementsByTagName("ClassificationCode")[0].childNodes[0].nodeValue;
                    }
        
                    var k = x[i].getElementsByTagName("DefinedContact");
                    if(k.length != 0) {
                        var y = x[i].getElementsByTagName("DefinedContact")[0].getElementsByTagName("URICommunication");
        
                        if(y.length != 0) {
                            var k = x[i].getElementsByTagName("DefinedContact")[0].getElementsByTagName("URICommunication")[0].childNodes;
        
                            if(k.length != 0) {
                                inputForm.txt_broker_url.value = x[i].getElementsByTagName("DefinedContact")[0].getElementsByTagName("URICommunication")[0].childNodes[0].nodeValue;
                            }
                        }
                    }
                }
            }
    
            //금액 설정
            var x = xmlDoc.getElementsByTagName("SpecifiedMonetarySummation");
            for(i = 0; i < x.length; i++) {
                inputForm.txt_charge_total.value = x[i].getElementsByTagName("ChargeTotalAmount")[0].childNodes[0].nodeValue;
    
                var y = x[i].getElementsByTagName("TaxTotalAmount");
                if(y.length != 0) {
                    inputForm.txt_tax_total.value = x[i].getElementsByTagName("TaxTotalAmount")[0].childNodes[0].nodeValue;
                }
            }
    
            //세금계산서 발행처 정보 가져오기
            rtMsg = fn_findInvoicesCustomer();
            if(rtMsg != "") {
                fn_procStopMsg(rtMsg);
                return false;
            }
    
            //금액 설정
            var x = xmlDoc.getElementsByTagName("SpecifiedMonetarySummation");
            if(x.length == 0) {
                fn_procStopMsg("XML파일에서 금액이 검색되지 않았습니다. 파일내용을 확인 하세요");
                return false;
            }
    
            for(i = 0; i < x.length; i++) {
                inputForm.txtAmount.value = x[i].getElementsByTagName("GrandTotalAmount")[0].childNodes[0].nodeValue;
            }
            
            //상세항목 설정
            var x = xmlDoc.getElementsByTagName("TaxInvoiceTradeLineItem");
    
            if(x.length == 0) {
                fn_procStopMsg("XML파일에서 품목 상세내역이 확인 되지 않습니다. 파일내용을 확인 하세요");
                return false;
            }
    
            var detailArr = new Array();
    
            for(i = 0; i < x.length; i++) {
                var detailObj = new Object();
    
                detailObj.hid_Seq = x[i].getElementsByTagName("SequenceNumeric")[0].childNodes[0].nodeValue;
    
                var k = x[i].getElementsByTagName("InvoiceAmount");
                if(k.length == 0) {
                    detailObj.hid_Amount = 0;
                }
                else {
                    detailObj.hid_Amount = x[i].getElementsByTagName("InvoiceAmount")[0].childNodes[0].nodeValue;
                }
    
                var k = x[i].getElementsByTagName("ChargeableUnitQuantity");
                if(k.length == 0) {
                    detailObj.hid_Qty = 0;
                }
                else {
                    detailObj.hid_Qty = x[i].getElementsByTagName("ChargeableUnitQuantity")[0].childNodes[0].nodeValue;
                }
    
                var k = x[i].getElementsByTagName("NameText");
                if(k.length == 0) {
                    detailObj.hid_ItemName = "";
                }
                else {
                    detailObj.hid_ItemName = x[i].getElementsByTagName("NameText")[0].childNodes[0].nodeValue;
                }
    
                var k = x[i].getElementsByTagName("PurchaseExpiryDateTime");
                if(k.length == 0) {
                    detailObj.hid_PurchaseDate = "";
                }
                else {
                    detailObj.hid_PurchaseDate = x[i].getElementsByTagName("PurchaseExpiryDateTime")[0].childNodes[0].nodeValue;
                }
    
                var k = x[i].getElementsByTagName("TotalTax");
                if(k.length == 0) {
                    detailObj.hid_TotTax = 0;
                }
                else {
                    var y = x[i].getElementsByTagName("TotalTax")[0].getElementsByTagName("CalculatedAmount");
                    if(y.length == 0) {
                        detailObj.hid_TotTax = 0;
                    }
                    else {
                        detailObj.hid_TotTax = x[i].getElementsByTagName("TotalTax")[0].getElementsByTagName("CalculatedAmount")[0].childNodes[0].nodeValue;
                    }
                }
    
                var k = x[i].getElementsByTagName("UnitPrice");
                if(k.length == 0) {
                    detailObj.hid_UnitPrice = 0;
                }
                else {
                    var y=x[i].getElementsByTagName("UnitPrice")[0].getElementsByTagName("UnitAmount");
                    if(y.length == 0) {
                        detailObj.hid_UnitPrice = 0;
                    }
                    else {
                        detailObj.hid_UnitPrice = x[i].getElementsByTagName("UnitPrice")[0].getElementsByTagName("UnitAmount")[0].childNodes[0].nodeValue;
                    }
                }
    
                detailArr.push(detailObj);
            }
    
            $("#hid_invoicer_detail").val(JSON.stringify(detailArr));
            
            fn_save(); //저장
        };
    
        reader.readAsText($("#file0")[0].files[0]);
        
    }


    /**
     * 해제
     **/
    function fn_clearXmlValue() {
        $("#delBill", parentWindow.document).click();
    }
    

    /**
     * 첨부파일 변경시 파일명 셋팅
     */
    function fn_fileUpload($obj) {

        var str = $obj.val();
        var fname = str.substring(str.lastIndexOf("\\") + 1);

        if(fname.indexOf("'") > -1) {
            alert("파일명에 ' 는 사용 할 수 없습니다.");
            return;
        }

        $obj.siblings("label").text(fname);
    }


    </script>
</head>

<body>
<div id="popArea">
    <!-- 제목 Area -->
    <div class="pop-title">XML 정보읽기</div>
    <!--// 제목 Area -->

    <!-- 버튼 Area -->
    <div class="pop-button-area">
        <table>
            <tr>
                <td>
                    <button type="button" class="ui-button eas-ui-button" onclick="fn_getXmlValue()"><span class="btn-p ui-icon ui-icon-link"></span>적용</button>
                    <button type="button" class="ui-button eas-ui-button" onclick="fn_clearXmlValue();"><span class="btn-p ui-icon ui-icon-link-broken"></span>해제</button>
                </td>
            </tr>
        </table>
    </div>
    <!--// 버튼 Area -->

    <!-- 입력 Area -->
    <form name="inputForm" id="inputForm" action="" method="post">
    <div class="input-area">
        <input type="hidden" name="txt_customer_pay_group"  id="txt_customer_pay_group" />
        <input type="hidden" name="txt_customer_id"         id="txt_customer_id" />
        <input type="hidden" name="txt_invoicer_tax_id"     id="txt_invoicer_tax_id" />
        <input type="hidden" name="txt_invoicer_emp_name"   id="txt_invoicer_emp_name" />
        <input type="hidden" name="txt_invoicer_address"    id="txt_invoicer_address" />
        <input type="hidden" name="txt_invoicer_fran_type"  id="txt_invoicer_fran_type" />
        <input type="hidden" name="txt_invoicer_fran_class" id="txt_invoicer_fran_class" />
        <input type="hidden" name="txt_invoicer_url"        id="txt_invoicer_url" />

        <input type="hidden" name="txt_invoicee_fran_num"   id="txt_invoicee_fran_num" />
        <input type="hidden" name="txt_invoicee_tax_id"     id="txt_invoicee_tax_id" />
        <input type="hidden" name="txt_invoicee_fran_name"  id="txt_invoicee_fran_name" />
        <input type="hidden" name="txt_invoicee_emp_name"   id="txt_invoicee_emp_name" />
        <input type="hidden" name="txt_invoicee_address"    id="txt_invoicee_address" />
        <input type="hidden" name="txt_invoicee_fran_type"  id="txt_invoicee_fran_type" />
        <input type="hidden" name="txt_invoicee_fran_class" id="txt_invoicee_fran_class" />
        <input type="hidden" name="txt_invoicee_url"        id="txt_invoicee_url" />

        <input type="hidden" name="txt_charge_total"        id="txt_charge_total" />
        <input type="hidden" name="txt_tax_total"           id="txt_tax_total" />
        <input type="hidden" name="txt_type_code"           id="txt_type_code" />
        <input type="hidden" name="txt_purpose_code"        id="txt_purpose_code" />
        <input type="hidden" name="txt_Description"         id="txt_Description" />

        <input type="hidden" name="hid_invoicer_detail"     id="hid_invoicer_detail" />

        <!-- BrokerParty -->
        <input type="hidden" name="txt_broker_fran_num"     id="txt_broker_fran_num" />
        <input type="hidden" name="txt_broker_fran_name"    id="txt_broker_fran_name" />
        <input type="hidden" name="txt_broker_tax_id"       id="txt_broker_tax_id" />
        <input type="hidden" name="txt_broker_emp_name"     id="txt_broker_emp_name" />
        <input type="hidden" name="txt_broker_address"      id="txt_broker_address" />
        <input type="hidden" name="txt_broker_fran_type"    id="txt_broker_fran_type" />
        <input type="hidden" name="txt_broker_fran_class"   id="txt_broker_fran_class" />
        <input type="hidden" name="txt_broker_url"          id="txt_broker_url" />

        <table class="input-table">
            <colgroup>
                <col width="25%" />
                <col width="75%" />
            </colgroup>
            <tr>
                <th>XML계산서</th>
                <td class="filebox">
                    <label for="file0">파일첨부</label><!--
                    --><input type="file" name="fl_xml_file" id="file0" onchange="fn_fileUpload($(this));" />
                </td>
            </tr>
        </table>

        <table class="input-table">
            <colgroup>
                <col width="25%" />
                <col width="75%" />
            </colgroup>
            <tr>
                <th>XML승인번호</th>
                <td><input type="text" name="txt_IssueID" id="txt_IssueID" size="50" readonly="readonly" /></td>
            </tr>
            <tr>
                <th>계산서 발행처(공급자)</th>
                <td>
                    <input type="text" name="txt_customer_regi" id="txt_customer_regi" size="20" readonly="readonly" /><!--
                    --><input type="text" name="txt_customer_name" id="txt_customer_name" size="50" readonly="readonly" />
                    <br />
                    <input type="text" name="txt_customer_num" id="txt_customer_num" size="20" readonly="readonly" maxlength="30" /><!--
                    --><input type="Text" name="txt_CustomerSite_Code" id="txt_CustomerSite_Code" size="7" readonly="readonly" />
                </td>
            </tr>
            <tr>
                <th>Invoice Date</th>
                <td><input type="text" name="txt_Invoice_Date" id="txt_Invoice_Date" size="20" readonly="readonly" /></td>
            </tr>
            <tr>
                <th>Amount(원화)</th>
                <td><input type="text" name="txtAmount" id="txtAmount" size="20" readonly="readonly" /></td>
            </tr>
        </table>
    </div>
    </form>
    <!--// 입력 Area -->
</div>
</body>
</html>
