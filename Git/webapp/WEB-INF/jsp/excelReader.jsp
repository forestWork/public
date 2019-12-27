<%
/********************************************************************************
 * javascript에서 엑셀파일 읽기
 * Sheet js 사용
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
    <script src="<c:url value='/js/sheetjs/dist/xlsx.full.min.js'/>"></script>

    <script type="text/javaScript">
    var xlsArray = new Array;

    /**
     * 적용
     */
    function fn_getXlsValue() {
        var reader = new FileReader();
        reader.onload = function(e) {
            var data = e.target.result;
            
            var wb;
            if(reader.readAsBinaryString == null) {
                var u8Ary = String.fromCharCode.apply(null, new Uint8Array(data));
                wb = XLSX.read(btoa(u8Ary), {type:"base64"});
            }
            else {
                wb = XLSX.read(data, {type:"binary"});
            }
            
            wb.SheetNames.forEach(function(item, index, array) {
                var xlsObj = XLSX.utils.sheet_to_json(wb.Sheets[item]);
                fn_getData(xlsObj);
            });
        };
        
        if(reader.readAsBinaryString == null)
            reader.readAsArrayBuffer($("#fl_excel_file")[0].files[0]);
        else
            reader.readAsBinaryString($("#fl_excel_file")[0].files[0]);
    }
    
    
    function fn_getData(obj) {
        var keys = Object.keys(obj[5]);
        
        for(var i = 8; i < obj.length; i++) {
            var data = obj[i];
            
            var productCode = data[keys[1]] == null ? "" : data[keys[1]];
            var deptCode    = data[keys[2]] == null ? "" : data[keys[2]];
            var accountCode = data[keys[3]] == null ? "" : data[keys[3]];
            var projectNum  = data[keys[4]] == null ? "" : data[keys[4]];
            var taskNum     = data[keys[5]] == null ? "" : data[keys[5]];
            var amount      = data[keys[6]] == null ? "" : data[keys[6]];
            var comment     = data[keys[7]] == null ? "" : data[keys[7]];

            if(productCode == "" && deptCode == "" && accountCode == "" && amount == "")
                continue;

            var xlsData = new Object();
            xlsData.productCode = productCode;
            xlsData.deptCode    = deptCode;
            xlsData.accountCode = accountCode;
            xlsData.projectNum  = projectNum;
            xlsData.taskNum     = taskNum;
            xlsData.amount      = amount;
            xlsData.comment     = comment;

            var errMsg = "";

            //xls validation
            errMsg = this.fn_validateXlsData(i, xlsData);
            if(errMsg != "") break;

            xlsData.deptName    = this.fn_dept(deptCode);
            xlsData.accountName = this.fn_account(accountCode, deptCode);

            //프로젝트번호 존재시 프로젝트 조회
            if(projectNum != "" && taskNum != "")
                xlsData = this.fn_project(xlsData);
            else
                xlsData.productName = this.fn_product(productCode, deptCode);

            //db validation
            errMsg = this.fn_validateAjaxData(i, xlsData);
            if(errMsg != "") break;

            xlsArray.push(xlsData);
        }

        if(errMsg != "") {
            alert(errMsg);
            return;
        }
    }
    
    
    /**
     * 제품
     */
    function fn_product(productCode, deptCode) {
        //To-Do
        return productName;
    }


    /**
     * 부서
     */
    function fn_dept(deptCode) {
        //To-Do
        return deptName;
    }


    /**
     * 계정
     */
    function fn_account(accountCode, deptCode) {
        //To-Do
        return accountName;
    }


    /**
     * 프로젝트
     */
    function fn_project(xlsData) {
        //To-Do
        return xlsData;
    }


    /**
     * 엑셀 데이터 검증
     */
    function fn_validateXlsData(i, xlsData) {
        var errMsg = "";

        if(xlsData.productCode == "")
            errMsg = "라인 " + i + " : 제품이 누락되었습니다.";
        else if(xlsData.deptCode == "")
            errMsg = "라인 " + i + " : 비용부서가 누락되었습니다.";
        else if(xlsData.accountCode == "")
            errMsg = "라인 " + i + " : 비용계정이 누락되었습니다.";
        else if((xlsData.projectNum != "" && xlsData.taskNum == "") || (xlsData.projectNum == "" && xlsData.taskNum != ""))
            errMsg = "라인 " + i + " : PJT와 TASK를 전부 입력하세요.";
        else if(xlsData.amount == "")
            errMsg = "라인 " + i + " : 금액이 누락되었습니다.";
        else if(isNaN(xlsData.amount))
            errMsg = "라인 " + i + " : 금액은 숫자를 입력하세요.";

        return errMsg;
    }


    /**
     * DB 데이터 검증
     */
    function fn_validateAjaxData(i, xlsData) {
        var errMsg = "";

        if(xlsData.productName == "")
            errMsg = "라인 " + i + " : 제품정보(" + xlsData.productCode + ")를 찾을 수 없습니다.";
        else if(xlsData.deptName == "")
            errMsg = "라인 " + i + " : 비용부서정보(" + xlsData.deptCode + ")를 찾을 수 없습니다.";
        else if(xlsData.accountName == "")
            errMsg = "라인 " + i + " : 계정정보(" + xlsData.accountCode + ")를 찾을 수 없습니다.";

        if(errMsg != "") return errMsg;

        //프로젝트 체크
        if(xlsData.projectNum != "" && xlsData.taskNum != "") {
            if(xlsData.projectName == null || xlsData.taskName == null || xlsData.organizationId == null)
                errMsg = "라인 " + i + " : 프로젝트정보(" + xlsData.projectNum + " - " + xlsData.taskNum + ")를 찾을 수 없습니다.";
        }

        return errMsg;
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


    /**
     * 첨부파일 양식 다운로드
     */
    function fn_download() {
        location.href = "<c:url value='/download/sample.xlsx'/>";
    }
    </script>
</head>

<body>
<div id="popArea">
    <!-- 버튼 Area -->
    <div class="pop-button-area">
        <table>
            <tr>
                <td>
                    <button type="button" id="btnDown" class="ui-button" onclick="fn_download();"><span class="btn-p ui-icon ui-icon-download"></span>양식 내려받기</button>
                    <button type="button" class="ui-button" onclick="fn_getXlsValue();"><span class="btn-p ui-icon ui-icon-link"></span>적용</button>
                    <button type="button" id="btnClos" class="ui-button" onclick="window.close();"><span class="btn-p ui-icon ui-icon-close"></span>닫기</button>
                </td>
            </tr>
        </table>
    </div>
    <!--// 버튼 Area -->

    <!-- 입력 Area -->
    <form name="inputForm" id="inputForm" action="" method="post">
    <div class="input-area">
        <table class="input-table">
            <colgroup>
                <col width="25%" />
                <col width="75%" />
            </colgroup>
            <tr>
                <th>차변 Excel파일</th>
                <td class="filebox">
                    <label for="fl_excel_file">파일첨부</label><!--
                    --><input type="file" name="fl_excel_file" id="fl_excel_file" onchange="fn_fileUpload($(this));" />
                </td>
            </tr>
        </table>
    </div>
    </form>
    <!--// 입력 Area -->
</div>
</body>
</html>
