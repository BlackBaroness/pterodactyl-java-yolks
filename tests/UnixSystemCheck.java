import com.sun.security.auth.module.UnixSystem;

class UnixSystemCheck {
    public static void main(String[] args) {
        var unix = new UnixSystem();
        if (unix.getUid() != Long.parseLong(args[0])
                || unix.getGid() != Long.parseLong(args[1]) || unix.getUsername() == null) {
            throw new AssertionError("Runtime UID/GID lookup failed");
        }
        System.out.println("UnixSystem OK: " + unix.getUsername());
    }
}
