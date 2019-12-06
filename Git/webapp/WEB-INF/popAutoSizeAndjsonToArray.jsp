<%
/********************************************************************************
 * 팝업 화면 사이즈 가변조절 및 Json데이터 Array 저장 처리
 ********************************************************************************/
%>
<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<!doctype html>
<html lang="kr">
<head>
    <meta charset="UTF-8">

    <style>
    .tcd {
        text-align: center;
        width: 100px;
        -ms-ime-mode: disabled;
    }
    .tol {
        width: 99%;
    }
    </style> 

    <script type="text/javascript">
    var gridView1;
    var gridView2;
    var dataProvider1;
    var dataProvider2;
    var gvMstSelData;
    var gvPopHeight = 0;

    $(document).ready(function() {
        //화면 사이즈 조절
        $("body").css("overflow-x", "hidden");

        gvPopHeight += $(".pop-title:eq(0)").outerHeight(true);
        gvPopHeight += $(".sub-title:eq(0)").outerHeight(true) + $(".pop-cond:eq(0)").outerHeight(true) + $("#grid1").outerHeight(true);
        gvPopHeight += $(".sub-title:eq(1)").outerHeight(true) + $(".pop-cond:eq(1)").outerHeight(true) + $("#grid2").outerHeight(true);
        gvPopHeight += $(".button-table").outerHeight(true);
        
        window.dialogHeight = gvPopHeight + "px";
        $("#popArea").css("width", document.documentElement.clientWidth);
    });


    /**
     * 완료
     **/
    function fn_save() {
        gridView2.commit(true);

        //validation
        var validationMsg = this.fn_validation();
        if(validationMsg != "") {
            alert(validationMsg);
            return;
        }

        var diffFlag = false;
        var param = new Array();
        
        var rowCnt = dataProvider2.getRowCount();
        for(var i = 0; i < rowCnt; i++) {
            var obj = dataProvider2.getJsonRow(i);
            param.push(obj); //Dtl - Array[Array.length]에 add 
        }
        
        //Mst - Array[0]에 add
        param.unshift($("#popForm").serializeObject());

        //DB저장
        var dataRt = true;
        if(confirmYn) {
            $.ajax({
                type : "POST",
                url : "/save.do",
                data : JSON.stringify(param),
                dataType : "json",
                contentType: "application/json",
                mimeType: "application/json",
                async: false,
                traditional : true
            })
            .done(function(data) {
                if(data.rtCd != 0 || data.rtMsg != null) {
                    var alertMsg = data.rtMsg;
                    if(alertMsg == "E01") alertMsg = "에러코드 1입니다.";
                    
                    alert("저장중 오류가 발생했습니다.\n" + alertMsg);
                    dataRt = false;
                    return;
                }
            })
            .fail(function(data) {
                console.log(data);
            });
        }
    }
    </script>
</head>

<body>
<div id="popArea">
    <!-- Mst Grid -->
    <div id="grid1" style="width:100%; height:125px;"></div>
    <!--// Mst Grid -->


    <!-- Dtl Grid -->
    <form name="popForm" id="popForm" method="post" onsubmit="return false;">
        <div id="grid2" style="width:100%; height: 210px; margin: 5px 0px;"></div>
    </form>
    <!--//  Dtl Grid력 -->


    <!-- 버튼 Area -->
    <table class="button-table">
        <colgroup>
            <col width="100%" />
        </colgroup>
        <tr>
            <td class="r">
                <button type="button" class="ui-button" onclick="fn_new();"><span class="btn-p ui-icon ui-icon-pencil"></span>신규</button>
                <button type="button" class="ui-button" onclick="fn_rowAdd();"><span class="btn-p ui-icon ui-icon-plusthick"></span>라인추가</button>
                <button type="button" class="ui-button" onclick="fn_rowDel();"><span class="btn-p ui-icon ui-icon-minusthick"></span>선택삭제</button>
                <span class="p">|</span>
                <button type="button" class="ui-button" onclick="fn_save();"><span class="btn-p ui-icon ui-icon-save"></span>완료</button>
            </td>
        </tr>
    </table>
    <!--// 버튼 Area -->
</div>
</body>
</html>
