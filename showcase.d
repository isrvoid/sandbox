import std.stdio;
import std.algorithm;
import std.array;

class User
{
private:
    immutable uint id;
    immutable string firstName, lastName;
    bool active;

public:
    this(uint id, string firstName, string lastName, bool active)
    {
        this.id = id;
        this.firstName = firstName;
        this.lastName = lastName;
        this.active = active;
    }

    uint getId() @property
    {
        return id;
    }

    string getFirstName() @property
    {
        return firstName;
    }

    string getLastName() @property
    {
        return lastName;
    }

    bool getActive() @property
    {
        return active;
    }

    void setActive(bool active)
    {
        this.active = active;
    }
}

string[] activeNamesByIdJava(User[] us)
{
    User[] users;
    foreach (u; us)
        if (u.getActive)
            users ~= u;

    users.sort!((a, b) => a.getId < b.getId);

    string[] names;
    foreach (u; users)
        names ~= u.getFirstName ~ " " ~ u.getLastName;

    return names;
}

string[] activeNamesById(User[] us)
{
    return us.filter!(a => a.getActive)
        .array().sort!((a, b) => a.getId < b.getId)
        .map!(u => u.getFirstName ~ " " ~ u.getLastName).array();
}

void main()
{
    auto inputUsers = [
        new User(11, "John", "Doe", false),
        new User(42, "Jane", "Roe", true),
        new User(23, "Joe", "Smith", true)
    ];

    auto activeNames = activeNamesById(inputUsers);
}
