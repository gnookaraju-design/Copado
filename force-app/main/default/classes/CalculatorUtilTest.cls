@isTest
public class CalculatorUtilTest {

    @isTest
    static void testAdd() {
        Integer result = CalculatorUtil.add(10, 20);
        System.assertEquals(30, result);
    }

    @isTest
    static void testIsPositive() {
        System.assertEquals(true, CalculatorUtil.isPositive(5));
        System.assertEquals(false, CalculatorUtil.isPositive(-5));
        System.assertEquals(false, CalculatorUtil.isPositive(0));
    }
}