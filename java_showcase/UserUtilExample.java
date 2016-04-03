import java.util.*;

class UserUtilExample {
    public static void main(String[] args) {
        List<User> inputUsers = new ArrayList<>();
        inputUsers.add(new User(11, "John", "Doe", false));
        inputUsers.add(new User(42, "Jane", "Roe", true));
        inputUsers.add(new User(23, "Joe", "Smith", true));

        List<String> activeNames = UserUtil.activeNamesById(inputUsers);
    }
}
