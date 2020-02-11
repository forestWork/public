package git.springAsync;

import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

@Service("SpringAsyncService")
public class SpringAsyncServiceImpl implements SpringAsyncService {

    @Resource(name="SpringAsyncDAO")
    private SpringAsyncDAO springAsyncDAO;

    @Override
    public void selectSpringAsynList(Map<String, Object> map) {
        springAsyncDAO.selectSpringAsynList(map);
    }
}
