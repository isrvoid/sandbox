import java.util.*;

public class UserUtil {
    public static List<String> activeNamesById(List<User> us) {
        List<User> users = new ArrayList<>();
        for (User u: us)
            if (u.getActive())
                users.add(u);

        Collections.sort(users, new Comparator<User>() {
            public int compare(User a, User b) {
                return a.getId() - b.getId();
            }
        });

        List<String> names = new ArrayList<>();
        for (User u: users)
            names.add(u.getFirstName() + " " + u.getLastName());

        return names;
    }
}
