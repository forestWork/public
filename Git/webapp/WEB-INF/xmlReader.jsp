<%
/********************************************************************************
 * javascript에서 xml 파일을 파싱 후 화면에 셋팅
 ********************************************************************************/
%>
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
    JINDO.xmlToObj = function(xml) {
        var obj = {}, que = [], depth = 0;

        //attribute를 해석하기 위한 함수
        var parse_attr = function(oobj, str) {
            str.replace(/([^=\s]+)\s*=\s*"([^"]*)"/g, function(a0,a1,a2) {
                oobj[a1] = a2;
            });
        }

        //주석, XML선언, 태그 사이 공백 등의 의미 없는 코드를 삭제
        xml = xml.replace(/<(\?|\!-)[^>]*>/g,'').replace(/>\s+</g, '><');

        //하위 노드가 없는 태그는 하나의 닫힌 태그로 수정
        xml = xml.replace(/<([^!][^ >]+)(\s[^>]*)?><\/\1>/g, '<$1$2 />').replace(/^\s+|\s+$/g, '');

        //함수 객체를 정규 표현식 처리의 인자로 줘서 iterator로 사용
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

        return obj;
    }


    function xmlToJson(xml) {
        //Create the return object
        var obj = {};

        //element
        if(xml.nodeType == 1) { 
            // do attributes
            if (xml.attributes.length > 0) {
            obj["@attributes"] = {};
                for (var j = 0; j < xml.attributes.length; j++) {
                    var attribute = xml.attributes.item(j);
                    obj["@attributes"][attribute.nodeName] = attribute.nodeValue;
                }
            }
        } 
        //text
        else if(xml.nodeType == 3) { 
            obj = xml.nodeValue;
        }

        //do children
        if(xml.hasChildNodes()) {
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
    
    
    function fn_read1() {
        var reader = new FileReader();
        reader.onload = function (e) {
            var data = e.target.result;
    
            var parser = new DOMParser();
            var xml = parser.parseFromString(data, "text/xml");
            
            //승인번호 설정
            var x = xmlDoc.getElementsByTagName("TaxInvoiceDocument");
            for(i = 0; i < x.length; i++) {
                inputForm.txt_IssueID.value = x[i].getElementsByTagName("IssueID")[0].childNodes[0].nodeValue;
                inputForm.txt_Invoice_Date.value = x[i].getElementsByTagName("IssueDateTime")[0].childNodes[0].nodeValue;

                var y = x[i].getElementsByTagName("DescriptionText");
                if(y.length != 0)
                    inputForm.txt_Description.value = x[i].getElementsByTagName("DescriptionText")[0].childNodes[0].nodeValue;
    
                //세금계산서 종류
                var y = x[i].getElementsByTagName("TypeCode");
                if(y.length != 0)
                    inputForm.txt_type_code.value = x[i].getElementsByTagName("TypeCode")[0].childNodes[0].nodeValue;
    
                //영수/청구 구분
                var y = x[i].getElementsByTagName("PurposeCode");
                if(y.length != 0)
                    inputForm.txt_purpose_code.value = x[i].getElementsByTagName("PurposeCode")[0].childNodes[0].nodeValue;
            }
        };
    
        reader.readAsText($("#file0")[0].files[0]);
    }
    
    
    function fn_read2() {
        var reader = new FileReader();
        reader.onload = function (e) {
            var data = e.target.result; //type:String
    
            var xmlDoc = JINDO.xmlToObj(data);
            
            //승인번호 설정
            x = xmlDoc["TaxInvoiceDocument"]; //xmlDoc.getElementsByTagName("TaxInvoiceDocument");
            if(x != null) {
                fn_procStopMsg("XML파일에서 승인번호가 검색되지 않았습니다. 파일내용을 확인 하세요");
                return false;
            }
    
            len = 1;
            if(x.constructor == Array) len = x.length;
            data = x;
    
            for(i = 0; i < len; i++) {
                if(data.constructor == Array) data = data[i];
    
                inputForm.txt_IssueID.value = data["IssueID"];
                inputForm.txt_Invoice_Date.value = data["IssueDateTime"];
    
                y = data["DescriptionText"];
                if(y != null) inputForm.txt_Description.value = y;
    
                //세금계산서 종류
                y = data["TypeCode"];
                if(y != null) inputForm.txt_type_code.value = data["TypeCode"];
    
                //영수/청구 구분
                y = data["PurposeCode"];
                if(y != null) inputForm.txt_purpose_code.value = data["PurposeCode"];
            }
        };
    
        reader.readAsText($("#file0")[0].files[0]);
    }
    
    
    function fn_read3() {
        var reader = new FileReader();
        reader.onload = function (e) {
            var data = e.target.result; //type:String
            
            var parser = new DOMParser();
            var xml = parser.parseFromString(data, "text/xml");
            var j = xmlToJson(xml);
        };
    
        reader.readAsText($("#file0")[0].files[0]);
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
