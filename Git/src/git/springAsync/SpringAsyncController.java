package git.springAsync;

import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class SpringAsyncController {

    @Resource(name = "SpringAsyncService")
    private SpringAsyncService springAsyncService;

    @RequestMapping(value = "/springAsynPop.lsis")
    public String springAsynPop() {
        return "springAsynPop";
    }

    @RequestMapping(value = "/selectSpringAsynList.lsis", method = RequestMethod.POST)
    public @ResponseBody Map<String, Object> selectSpringAsynList(@RequestParam Map<String, Object> map) {

        springAsyncService.selectSpringAsynList(map);

        return map;
    }
}
