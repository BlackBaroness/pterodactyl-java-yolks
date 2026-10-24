import com.sun.security.auth.module.UnixSystem;

class UnixSystemCheck {
    public static void main(String[] args) {
        System.out.println("Java: " + System.getProperty("java.runtime.version")
                + "; vendor=" + System.getProperty("java.vendor"));
        var unix = new UnixSystem();
        System.out.println("UnixSystem: username=" + unix.getUsername()
                + ", uid=" + unix.getUid() + ", gid=" + unix.getGid());
        if (args.length == 2 && (unix.getUid() != Long.parseLong(args[0])
                || unix.getGid() != Long.parseLong(args[1]) || unix.getUsername() == null)) {
            throw new AssertionError("Runtime UID/GID lookup failed");
        }
        System.out.println("UnixSystem OK: " + unix.getUsername());
    }
}
