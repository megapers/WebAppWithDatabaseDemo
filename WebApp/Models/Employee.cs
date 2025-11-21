namespace WebApp.Models
{
    public class Employee
    {
        public int Id { get; set; }
        public required string Fullname { get; set; }
        public required string Department { get; set; }
        public required string Email { get; set; }
        public required string Phone { get; set; }
        public required string Address { get; set; }
    }
}
