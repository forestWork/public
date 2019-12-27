<%
/********************************************************************************
 * js는 싱글스레드라서 다건으로 dom 생성시에는 loading bar가 작동을 하지 않음.
 * 그것을 해결하기위해 interval을 사용하여 처리.
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
    /**
     * 업로드 팝업
     */
    function excelPop() {
        var url = "<c:url value='/git/info/excelPop.lsis'/>";
        var options = "dialogWidth=750px;dialogHeight=200px;scroll:yes;status:no;";
        var vReturn = window.showModalDialog(url, self, options);

        if(vReturn == null || vReturn == undefined) return;
        /*
        vReturn = {["a":"a1","b":"b1","c":"c1", ...]
                  ,["a":"a2","b":"b2","c":"c2", ...]
                  ,["a":"a3","b":"b3","c":"c3", ...]
                  , ... 
                  ,["a":"an","b":"bn","c":"cn", ...]
                  }
        */

        gfnShowLoadingbar(); //show loading bar
        
        var i = 0;
        var interval = setInterval(function() {
            if(i < vReturn.length) {
                this.addDomXls(vReturn[i++]);
            }
            else {
                gfnHideLoadingbar(); //hide loading bar
                clearInterval(interval);
            }
        }, 0);
    }


    /**
     * 차변 자동 추가 엑셀
     * obj : 차변업로드의 결과 obj
     */
    function addDomXls(obj) {
        addDom();

        var cls = "." + $("button[name=btnItemDel]:last").closest("tr").attr("class");
        $(cls).find("input[type=text]").val("");

        $("input[name=a]:last").val(obj.a);
        $("input[name=b]:last").val(obj.b);
        $("input[name=c]:last").val(obj.c);
        $("input[name=d]:last").val(obj.d);

        this.searchName($(cls).find("button[name=schName]"));
    }
    
    
    /**
     * dom 정보 추가
     */
    function addDom() {
        var strSplit  = $("#tbItem tr:last").attr("class").split(" ");
        var lastClass = (strSplit[0].indexOf("item") > -1) ? strSplit[0] : strSplit[1];
        var itemCnt   = Number(lastClass.replace("acntg-item", "")) + 1;

        //jquery ui 제거
        $("." + lastClass).find("input:radio").checkboxradio("destroy");
        $("." + lastClass).find("input:checkbox").checkboxradio("destroy");
        $("." + lastClass).find(".date").datepicker("destroy");
        $("." + lastClass).find(".date").attr("id", "");
        $("." + lastClass).find("select").selectmenu("destroy");
        $("." + lastClass).find("select").attr("id", "");

        var $newTr = $("." + lastClass).clone();

        $newTr.each(function(idx) {
            $(this).removeClass(lastClass);

            if(idx == 0)
                $(this).find("th span:eq(0)").text("ITEM " + itemCnt);

            if(idx == 11) {
                var name = $(this).find("input:radio").attr("name").split("_temp")[0] + "_temp" + itemCnt;
                $(this).find("input:radio").each(function() {
                    $(this).attr("name", name);
                });
            }
        });

        $newTr.find("input[name=id]").val("");

        $("#tbItem:last").append($newTr);

        //jquery ui 셋팅
        $(".radio").checkboxradio();
        $(".check").checkboxradio();
        $(".curr").number(true, 0); //통화
        $(".dot").number(true, 2);  //통화,소수점
        $(".num").mask('0#');       //숫자
        datepickerDateInit(".date");
        $(".select").selectmenu({width:"250px"});
    }
    
    
    /**
     * 이름 조회
     * $obj : 이름 조회버튼 - $("button[name=schName]:eq(n)")
     */
    function searchName($obj) {
        var idx = $("button[name=schName]").index($obj);

        var param1 = $("input[name=a]:eq(" + idx + ")").val();
        var param2 = $("input[name=b]:eq(" + idx + ")").val();
        var param  = {"param1":param1, "param2":param2};
        var url    = "<c:url value='/git/info/searchName.lsis'/>";

        xhrPostJson(url, param).done(function(data) {
            $("button[name=delName]:eq(" + idx + ")").click();

            if(data.result == null || data.result.length == 0) return;

            var result = data.result[0];

            $("input[name=e]:eq(" + idx + ")").val(result.e);
            $("input[name=f]:eq(" + idx + ")").val(result.f);

            searchInfo($obj);
        });
    }
    
    
    /**
     * info 보이기
     * $accObj : 조회버튼 - $("button[name=schName]:eq(n)")
     **/
    function searchInfo($accObj) {
        var param1 = $("input[name=e]:eq(" + idx + ")").val();
        var param2 = $("input[name=f]:eq(" + idx + ")").val();
        var param  = {"param1":param1, "param2":param2};
        var url    = "<c:url value='/git/info/searchInfo.lsis'/>";

        xhrPostJson(url, param).done(function(data) {
            var result = data.result;
            if(result == undefined || result.length == 0) return;

            //UI 그리기
            var trClass = "." + $accObj.closest("tr").attr("class");
            $(trClass).find("button[name=btnInfo]").show();

            for(var i = 0; i < result.length; i++) {
                map = result[i];
                
                $obj = $(trClass + ":eq(" + (parseInt(nValue) - 1) + ")");

                $obj.children("th").text(map.header);
                $obj.find("input[name^=flag]").val(map.flag);
                $obj.find("span[name^=remark]").text(map.remark);

                fn_transAcct();

                $obj.show();
            }
        });
    }


    /**
     * Info Dtl 생성
     * num : tr 타입번호
     * $tr : tr obj
     **/
    function searchInfoDtl(num, $tr) {
        var html = "";

        if(num == 4) {
            var url   = "<c:url value='/git/info/searchInfoDtl1.lsis'/>";

            html += '<select name="t" class="select">';
            html += '<option value="">' + $("#cboSelect").val() + '</option>';

            xhrPostJson(url, param, false).done(function(data) {
                var result = data.result;
                if(result == undefined || result.length == 0) return;

                for(var i = 0; i < result.length; i++) {
                    html += '<option value="' + result[i].col1 + '">' + result[i].col2 + '</option>';
                }
            });

            html += '</select>';

            $tr.find("input[name=at]").attr("readonly", true);
        }
        else if(num == 2 || num == 3 || num == 41) {

            if(num == 41) num = 4;

            var idx = $("input[name=at" + num + "]").index($tr.find(("input[name=at" + num + "]")));
            var selector = "input[name=at" + num + "]:eq(" + idx + ")";

            datepickerDateInit(selector);
            $(selector).addClass("date");
            $(selector).attr("readonly", false);
        }
        else if(num == 1 || num == 21 || num == 5) {

            if(num == 21) num = 2;

            var btnId = "";
            if(num == 1) btnId = "apple";
            else if(num == 2) btnId = "banana";
            else if(num == 5) btnId = "pear";

            html += '<button type="button" name="sch' + btnId + '" class="ui-button"><span class="btn-p ui-icon ui-icon-search"></span></button><!--';
            html += '--><button type="button" name="del' + btnId + '" class="ui-button"><span class="btn-p ui-icon ui-icon-erase"></span></button>';

            $tr.find("input[name=at" + num + "]").attr("readonly", true);
        }
        else {
            $tr.find("input[name=at" + num + "]").attr("readonly", true);
        }

        $tr.find("span[name=spnT" + num + "]").empty();
        $tr.find("span[name=spnT" + num + "]").append(html);

        if(num == 4) $("select[name=t]").selectmenu({width:"250px"});
    }
    </script>
</head>

<body>
...
</body>
</html>
