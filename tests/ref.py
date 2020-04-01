import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import curve_fit

def f(x, a, b):
    """ function to emulate an exponential model, a & b are free parameters """
    return a*np.exp(b * x)


def main():
    dataset_size = 12
    x = np.arange(0, dataset_size)
    y = f(x, 15., .13)*np.random.normal(loc=1., #mean of gaussian PDF
                                    scale=.2, #std of gaussian PDF
                                    size=dataset_size)

    print(">>",x)
    print(">>",y,"\n")
    plt.plot(x, y, 'o', label='data',color="black")

    popt, pcov =  curve_fit(f, x, y)

    # pcov is obtained
    # from the Hessian matrix (inverted Jacobian) at the optimal parameters
    # https://github.com/scipy/scipy/blob/v1.4.1/scipy/optimize/minpack.py#L763
    # and then all values inside this matrix are multiplied by chi**2/ndf to give pcov
    # https://github.com/scipy/scipy/blob/v1.4.1/scipy/optimize/minpack.py#L801
    perr = np.sqrt(np.diag(pcov))
    # print(popt)
    # print(perr)

    fitres = "fit: a={:5.3f}+/-{:5.3f}, b={:5.3f}+/-{:5.3f}".format(popt[0],perr[0],
                                                            popt[1],perr[1])

    print("fit results\n",fitres)

    plt.plot(x, f(x, *popt), 'r-',label=fitres)

    y_lwr = f(x,
              popt[0] - perr[0],
              popt[1] - perr[1]
    )
    y_upr = f(x,
              popt[0] + perr[0],
              popt[1] + perr[1]
    )
    plt.fill_between(x, y_lwr, y_upr, alpha=0.2)

    plt.xlabel('x')
    plt.ylabel('y')
    plt.legend()
    plt.savefig('nref-py.png')
    print("covariance\n",pcov)


if __name__ == '__main__':
    main()

